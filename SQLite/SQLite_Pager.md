# SQLite Pager 소스 코드 분석

- pager.c, pcache.c 코드 및 헤더에서 data 를 읽어오는 함수 위주로 분석


## Page Get

- pager 에서 특정 데이터 페이지를 읽어오는 함수는 `sqlite3PagerGet` 함수이다. 해당 함수는 바로 pager 의 get 함수를 호출한다. 

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

- TODO: `pager_write_pagelist` 함수 해석
