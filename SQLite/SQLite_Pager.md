# SQLite Pager 소스 코드 분석

- pager.c, pcache.c 코드 및 헤더에서 data 를 읽어오는 함수 위주로 분석


## Page Get


### sqlite3PagerGet

- pager 에서 특정 데이터 페이지를 읽어오는 함수는 `sqlite3PagerGet` 함수이다. 해당 함수는 바로 pager 의 get 함수를 호출한다. 

| Caller | btreeGetPage(btree.c), getAndInitPage(btree.c), pager_incr_change_counter(pager.c - read page 1), sqlite3PagerCommitPhaseOne(pager.c - read page 1) ...|
|:------:|:-------------------------:|

```c
/* Dispatch all page fetch requests to the appropriate getter method.
*/
int sqlite3PagerGet(
  Pager *pPager,      /* The pager open on the database file */
  Pgno pgno,          /* Page number to fetch */
  DbPage **ppPage,    /* Write a pointer to the page here */
  int flags           /* PAGER_GET_XXX flags */
){
  // NOTE: setGetterMethod 에서 xGet 함수 포인터 설정함: pPager->xGet = getPageNormal;
  return pPager->xGet(pPager, pgno, ppPage, flags);   
}
```

- `getPageNormal()` 함수에 대해서 보기 전에 해당 함수의 흐름은 다음과 같다. 자세한 내용은 [링크](https://github.com/Csoyee/SQLite/blob/39a0740c0834039525ee3840fe2139411bea499f/sqlite-src-3290000/src/pager.c#L5408) 의 주석을 참조하자.
  1. 요청한 페이지가 이미 cache 에 있으면 바로 해당 페이지를 받아서 return 한다.
  2. 그렇지 않으면 새로운 page object 를 할당하여 database file 의 페이지를 읽어온다 (어떤 경우에는 새 페이지 할당이 필요하지 않을 수도 있다.)
  3. 읽어오는 데이터 사이즈, 페이지의 상태 (e.g., PAGER_GET_NOCONTENT) 에 따라서 zero pending 이 필요한 경우가 있다. 
  
```c
static int getPageNormal(
  Pager *pPager,      /* The pager open on the database file */
  Pgno pgno,          /* Page number to fetch */
  DbPage **ppPage,    /* Write a pointer to the page here */
  int flags           /* PAGER_GET_XXX flags */
){
  int rc = SQLITE_OK;
  PgHdr *pPg;
  u8 noContent;                   /* True if PAGER_GET_NOCONTENT is set */
  sqlite3_pcache_page *pBase;

  if( pgno==0 ) return SQLITE_CORRUPT_BKPT; // NOTE: 페이지 넘버가 invalidate 하면 에러코드를 return 한다. 

  // NOTE: Page Cache 에서 데이터를 찾는다.
  pBase = sqlite3PcacheFetch(pPager->pPCache, pgno, 3);
  
  // NOTE: pBase 가 0 이면 sqlite3PCacheFetch 에서 reuse 할 클린 페이지나 cache limit 에 도달하여 새 페이지를 할당하지 못했음을 의미한다.
  if( pBase==0 ){
    pPg = 0;
    rc = sqlite3PcacheFetchStress(pPager->pPCache, pgno, &pBase);  // NOTE: pagerStress 함수 불러서 allocate 할 공간 확보 
    
    /* 메모리 부족하거나 에러 발생하면 에러코드 리턴*/
  }
  
  // NOTE: sqlite3PcacheFetch 를 통해서 얻은 sqlite3_pcache_page 오브젝트를 PgHdr 오브젝트로 변환함.
  pPg = *ppPage = sqlite3PcacheFetchFinish(pPager->pPCache, pgno, pBase);
  
  if( pPg->pPager && !noContent ){
    // NOTE: pager 에 데이터가 있으면 HIT statistic 을 늘리고 SQLITE_OK 리턴함.
    pPager->aStat[PAGER_STAT_HIT]++;
    return SQLITE_OK;
  }else{
    // 여러 error 체크를 하고 만일 noContent 이면 zero data setting 을 한다 (:: memset(pPg->pData, 0, pPager->pageSize);)
    // 에러가 없는 경우
    pPager->aStat[PAGER_STAT_MISS]++;
    rc = readDbPage(pPg); // NOTE: OS 에서 데이터를 읽어온다.
  
    // 새로 읽어온 데이터 기반으로 pagehash 갱신
  }
```


## Page Write

### sqlite3PagerWrite

- 해당 함수는 직접 파일에 데이터를 쓰는 함수는 아니고 page update 이전에 해당 페이지가 writable 하다고 표시하는 함수이다. 따라서 저널에 write 페이지를 추가하는 작업 및 pcache 에 dirty 표시하는 하는 작업 등을 수행한다. 일반적으로 해당 함수의 return 값이 `SQLITE_OK` 이면 put4byte 와 같이 데이터를 쓰는 작업을 수행한다.

- pcache 에 dirty flag 를 세팅하면 flag 는 `PGHDR_DIRTY` 상태가 되고 저널이 성공적으로 업데이트 되면 `PGHDR_WRITABLE` 상태가 된다.


```c
static int pager_write(PgHdr *pPg)}
  Pager *pPger = pPg->pPager;
  int rc = SQLITE_OK;
  
  // assert 조건 확인, 저널 열기 ...
  
  // 수정할 페이지에 더티 플래그를 세팅하고 Dirty List 를 갱신함. 
  sqlite3PcacheMakeDirty(pPg); 
  
  // 롤백 저널 갱신 
  
  // WRITEABLE 플래그로 변경 - 이제 write 를 할 수 있다.
  pPg->flags |= PGHDR_WRITABLE;
  
  // DB 사이즈 갱신
}
```


### pager_write_pagelist 
- commit 시에 `pager_write_pagelist` 함수를 불러 page cache 에 있는 dirty list 를 disk 로 쓰는 작업을 수행한다. 

| Caller | pagerStress(pager.c - pcache flush 시에 부르는 함수), sqlite3PagerCommitPhaseOne(pager.c) ...|
|:------:|:-------------------------:|


```c
static int pager_write_pagelist(Pager *pPager, PgHdr *pList){
  int rc = SQLITE_OK;                  /* Return code */
  
  while ( rc==SQLITE_OK && pList ){
    Pgno pgno = pList->pgno; 
   
    // NOTE: page 번호가 db size 보다 크거나 don't write flag 가 세팅되어있으면 write 하지 않는다. 
    if( pgno<=pPager->dbSize && 0==(pList->flags&PGHDR_DONT_WRITE) ){
      i64 offset = (pgno-1)*(i64)pPager->pageSize;   /* Offset to write */
      char *pData;                                   /* Data to write */    

      if( pList->pgno==1 ) pager_write_changecounter(pList);

      /* NOTE: pList->pData 값을 pData 로 */
      CODEC2(pPager, pList->pData, pgno, 6, return SQLITE_NOMEM_BKPT, pData);

      /* NOTE: database page 에 pcache 에 있는 데이터를 써넣음 */
      rc = sqlite3OsWrite(pPager->fd, pData, pPager->pageSize, offset);

      /* 페이지 업데이트가 되었기 때문에 데이터 파일 버전 정보를 갱신하고 
      ** 데이터베이스 파일 사이즈가 증가하였으면 파일 사이즈를 갱신한다.
      */
      if( pgno==1 ){
        memcpy(&pPager->dbFileVers, &pData[24], sizeof(pPager->dbFileVers));
      }
      if( pgno>pPager->dbFileSize ){
        pPager->dbFileSize = pgno;
      }
      pPager->aStat[PAGER_STAT_WRITE]++;   // stat 갱신

      /* Update any backup objects copying the contents of this pager. */
      sqlite3BackupUpdate(pPager->pBackup, pgno, (u8*)pList->pData);

      // debug 메세지 출력 (어떤 페이지에 대한 write 를 했는지) 
    }else{
      // debug 메세지 출력 (해당 page number 에 대한 write 수행하지 않았음) 
    }
    // 새로 읽어온 데이터 기반으로 pagehash 갱신, 다음 dirty list 로 갱신
    pager_set_pagehash(pList);
    pList = pList->pDirty;
  }
  
  return rc;
}
```

