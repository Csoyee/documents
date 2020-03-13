# SQLite Btree 소스 코드 분석 

- btree.c 및 헤더 파일 분석 
- 주로 operation call path 에 맞추어 분석 

## Cell 

- Cell 은 가변 길이의 스트링으로 단일 payload (|key |data  |) 를 저장한다. 단일 cell 안에는 cell structure 을 위한 정보 및 key, data 의 byte 길이를 포함하고 있다. 
- 관련 함수로: insertCell, dropCell, clearCell ... 등이 있다. 인자로 page 와 cell 관련 idx 정보등을 전달하기 때문에 사용자 입장에서는 역할만 이해하고 내부까지 자세히 알 필요는 없다.
  - insertCell : 새로운 cell 을 페이지 내의 특정 인덱스에 삽입한다. 인자로 페이지 번호와 인덱스 뿐 아니라 새롭게 넣을 셀 내용 및 내부 정보들의 길이 등을 전달한다.
  - dropCell: page 에서 i 번째 인덱스에 있는 셀을 제거한다. 이미 cell content 가 free 되었으며 별 영향이 없다. 인자로 페이지 번호, 인덱스 셀 크기 등을 전달한다. 
  - clearCell: 주어진 cell 에서 overflow page 를 free 한다. 
  - findCell: 페이지와 인덱스 정보를 넘겨주면 cell 위치를 알려주는 함수이다.

## Create 

- SQLite 는 테이블 당 btree 를 유지하며 이에 따라 table creation 시에 `OP_CreateBtree` 작업을 수행한다. 이 때 `sqlite3BtreeCreateTable()` 함수를 콜한다.


## Insert 

- SQLite 에서 데이터 insert 시에 `OP_Init` 작업을 수행하며 해당 작업에서 `sqlite3BtreeInsert()` 함수를 콜한다. 


### sqlite3BtreeInsert

- 함수 이름 그대로 새로운 레코드를 BTree 에 삽입하는 함수이다.
- 매개변수
  - pCur: 레코드가 삽입되어야하는 테이블을 알려주기 위해서만 사용되고 그 이후에는 아무 위치나 가리키고 있다 
  - pX: 새롭게 삽입할 레코드 이다. (pX.nKey 는 키값으로 rowid 나 row 의 integer PKEY 값을 갖는다. | pX.nData,pData,nZero 는 데이터를 포함한다.)
  - seekResult: 해당 값이 0 이 아니면 커서가 현재 삽입될 셀의 위치에 인접한 위치를 가리킴을 의미한다. 만일 음수 값이면 pCur 이 넣을 키 값보다 작은 키값을 갖는 위치를 포인팅하고 있음을 의미한다. 만일 seekResult 값이 0 이면 pCur이 알수없는 위치를 가리키고 있음을 의미하고 이 때는 삽입할 위치를 미리 찾아내야 한다.

```c
int sqlite3BtreeInsert(
  BtCursor *pCur,                /* Insert data into the table of this cursor */
  const BtreePayload *pX,        /* Content of the row to be inserted */
  int flags,                     /* True if this is likely an append */
  int seekResult                 /* Result of prior MovetoUnpacked() call */
)
  int rc;
  int loc = seekResult;          /* -1: before desired location  +1: after */
  int szNew = 0;
  int idx;
  MemPage *pPage;
  Btree *p = pCur->pBtree;
  BtShared *pBt = p->pBt;
  unsigned char *oldCell;
  unsigned char *newCell = 0;
  
  // TODO, 해당 루틴을 왜 하는지 확인하기
  if( pCur->curFlags & BTCF_Multiple ){
    rc = saveAllCursors(pBt, pCur->pgnoRoot, pCur);
    if( rc ) return rc;
  }
  
  if( RowID 가 있는 테이블인 경우 ){
    // 
    invalidateIncrblobCursors(p, pCur->pgnoRoot, pX->nKey, 0);
    
    if( (pCur->curFlags&BTCF_ValidNKey)!=0 && pX->nKey==pCur->info.nKey ){ 
      // 커서가 overwrite 해야하는 엔트리를 가리키고 있는 경우
      
      if( pCur->info.nSize!=0
       && pCur->info.nPayload==(u32)pX->nData+pX->nZero
      ){
        /* 만일 새 entry 가 이전의 entry 와 동일 사이즈이면 그냥 overwrite 를 한다. */
        return btreeOverwriteCell(pCur, pX);
      }
    }else if( loc==0 ){
      // 만일 커서가 overwrite 해야하는 cell 을 가리키고 있지 않거나 adjacent cell 이 아니면
      // 커서를 이동 시켜서 overwrite 해야하거나 인접한 cell 을 가리키도록 커서를 이동시킨다.
      rc = sqlite3BtreeMovetoUnpacked(pCur, 0, pX->nKey, flags!=0, &loc);
      if( rc ) return rc; // 에러인 경우에만 리턴
    }
  } else {
    // ROWID 가 없는 테이블이거나 인덱스인 경우.
    
    // 만일 오버라이트를 해야하는 셀을 가리키고 있지 않거나, 
    // 새로운 셀이 입력되는 경우에는 커서가 인접 셀을 가리키고 있지 않을 때 커서를 인접 셀로 이동시킨다.
    if( loc==0 && (flags & BTREE_SAVEPOSITION)==0 ){
      if( pX->nMem ){
        UnpackedRecord r;
        // 레코드 값 세팅
        rc = sqlite3BtreeMovetoUnpacked(pCur, &r, 0, flags!=0, &loc);
      }else{
        rc = btreeMoveto(pCur, pX->pKey, pX->nKey, flags!=0, &loc);
      }
      if( rc ) return rc; // 에러인 경우에만 리턴
    }
    
    // 만일 커서가 이미 오버라이트 할 엔트리를 가리키고 있고 새 컨텐츠가 올드 컨텐츠와 같은 경우에는 overwrite 최적화를 사용한다.
    if( loc==0 ){
      getCellInfo(pCur);
      if( pCur->info.nKey==pX->nKey ){
        BtreePayload x2; 
        x2.pData = pX->pKey;
        x2.nData = pX->nKey;
        x2.nZero = 0;
        return btreeOverwriteCell(pCur, &x2); // 만일 커서가 이제 overwrite 할 키를 가리키고 있고 그 사이즈가 같으면 overwrite 한다.
      }
    }
  }
  
  // NOTE: 여기까지 왔다면 키의 크기가 달라서 overwrite 할 수 없었던 경우가 된다. pCur 은 모두 인접 혹은 해당 키를 가리키고 있는 상태가 되어있다. 
  
  // 셀의 내용을 채우고
  rc = fillInCell(pPage, newCell, pX, &szNew);
  if (rc) goto end_insert;  // 에러 발생 시 그냥 리턴
  
  if (loc == 0) {
    CellInfo info;
    
    rc = sqlite3PagerWrite(pPage->pDbPage); // write 할 것이기 때문에 해당 영역 writable 표시하고
    if( rc ){ // 에러 나면 그냥 리턴 
      goto end_insert;
    }
    oldCell = findCell(pPage, idx); // 기존 값이 존재하던 위치를 받아온다.
    if( !pPage->leaf ){
      memcpy(newCell, oldCell, 4);
    }
    rc = clearCell(pPage, oldCell, &info); // 오버플로우 난 페이지가 있으면 free 를 한다. 
    if( info.nSize==szNew && info.nLocal==info.nPayload 
     && (!ISAUTOVACUUM || szNew<pPage->minLocal)
    ){
      /* 만일 올드 셀이랑 새롭게 쓸 셀이 동일 사이즈를 가지는 경우에 오버라이트 한다. */
      if( oldCell+szNew > pPage->aDataEnd ) return SQLITE_CORRUPT_BKPT;
      memcpy(oldCell, newCell, szNew);
      return SQLITE_OK;
    }
    dropCell(pPage, idx, info.nSize, &rc); // page 에서 i 번째 cell 을 제거함 
    if( rc ) goto end_insert;
  }
  
  insertCell(pPage, idx, newCell, szNew, 0, 0, &rc); // index i 번째에 새로운 셀을 삽입한다. 만일 딱 맞게 들어가면 문제가 없지만, 맞지않는 경우에는 pTemp 에 사본을 만든다.
   
  // 만일 현재까지 발생한 에러가 없고, pPage 가 overflow cell 을 가지고 있는 경우 balance() call 을 통해서 tree 안에 있는 cell 을 재배치한다. 
  if(pPage->nOverflow) {
    rc = balance(pCur);
    
    // balance 가 실패하더라도 overflow 개수는 0개로 수정해주어야 한다. 물론 내부 데이터 구조 corruption 은 발생하게 된다. 
    // 또한 커서 상태를 invalid 로 바꾸어서 현재 커서의 위치를 계속해서 저장할 필요가 없도록 한다.
  }
}

// TODO - move 관련 내용, cell 관련 내용 정리하기.

```

## Etc

- `sqlite3BtreeIntegerKey` 함수는 인자로 cursor 을 넘겨줬을 때 이에 해당하는 integer key 를 리턴하는 함수이다. 
