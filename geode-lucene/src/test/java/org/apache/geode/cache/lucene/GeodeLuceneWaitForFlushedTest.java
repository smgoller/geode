package org.apache.geode.cache.lucene;

import static org.apache.geode.cache.lucene.test.LuceneTestUtilities.INDEX_NAME;
import static org.apache.geode.cache.lucene.test.LuceneTestUtilities.REGION_NAME;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;

import org.junit.Assert;
import org.junit.Test;

import org.apache.geode.cache.PartitionAttributesFactory;
import org.apache.geode.cache.PartitionedRegionStorageException;
import org.apache.geode.cache.RegionFactory;
import org.apache.geode.cache.RegionShortcut;
import org.apache.geode.cache.asyncqueue.AsyncEventQueue;
import org.apache.geode.cache.asyncqueue.internal.AsyncEventQueueImpl;
import org.apache.geode.cache.lucene.internal.InternalLuceneIndex;
import org.apache.geode.cache.lucene.internal.LuceneIndexForPartitionedRegion;
import org.apache.geode.cache.lucene.internal.LuceneServiceImpl;
import org.apache.geode.cache.lucene.internal.repository.serializer.Type1;
import org.apache.geode.cache.lucene.test.LuceneTestUtilities;
import org.apache.geode.test.dunit.VM;

public class GeodeLuceneWaitForFlushedTest extends LuceneDUnitTest {

   @Test
  public void testRaceBetweenCloseCacheAndWritingLuceneIndex() throws ExecutionException, InterruptedException {
    VM proxy = VM.getVM(2);

    //Create region and index on two members
    createRegion(dataStore1, RegionShortcut.PARTITION_REDUNDANT_PERSISTENT);
    createRegion(dataStore2, RegionShortcut.PARTITION_REDUNDANT_PERSISTENT);

    createRegion(proxy, RegionShortcut.PARTITION_PROXY_REDUNDANT);

    proxy.invoke(() -> {
      for(int i = 0; i < 10010; i++) {
        getCache().getRegion(REGION_NAME).put("key" + i, "value" + i);
      }
    });

    //Pause the queue
    dataStore1.invoke(() -> LuceneTestUtilities.pauseSender(getCache()));
    dataStore2.invoke(() -> LuceneTestUtilities.pauseSender(getCache()));

    //Remove an entry
    proxy.invoke(() -> {
      for(int i = 1; i < 10010; i++) {
//        getCache().getRegion(REGION_NAME).remove("key" + i, "value" + i);
        getCache().getRegion(REGION_NAME).remove("key" + i);
      }
    });

//    dataStore1.invoke(() -> LuceneTestUtilities.resumeSender(getCache()));
//    dataStore2.invoke(() -> LuceneTestUtilities.resumeSender(getCache()));

    //Shutdown the datastores
    final CompletableFuture<Void>
        future1 =
        CompletableFuture.runAsync(() -> dataStore1.invoke(() -> getCache().close()));
    final CompletableFuture<Void>
        future2 =
        CompletableFuture.runAsync(() -> dataStore2.invoke(() -> getCache().close()));

    //Let the close cache finish
    future1.get();
    future2.get();

    //Recreate the region
    CompletableFuture<Void> recreateFuture1 = createRegionAsync(dataStore1);
    CompletableFuture<Void> recreateFuture2 = createRegionAsync(dataStore2);
    recreateFuture1.get();
    recreateFuture2.get();

//    Thread.sleep(10000);

    dataStore1.invoke(this::assertLuceneIndexHasOneEntry);

  }

  private void assertLuceneIndexHasOneEntry()
      throws InterruptedException, LuceneQueryException {

    LuceneService service = LuceneServiceProvider.get(getCache());

    LuceneIndex index = service.getIndex(INDEX_NAME,REGION_NAME);
    String aeqId = LuceneServiceImpl.getUniqueIndexName(index.getName(), index.getRegionPath());
    System.out.println("NABA --- last verification");
    AsyncEventQueueImpl aeq = (AsyncEventQueueImpl) getCache().getAsyncEventQueue(aeqId);
    System.out.println("NABA :: " +aeq + "NABA :: ID " +aeqId);
    System.out.println("NABA :Prewait Queued events:" + aeq.getStatistics().getEventsQueued());

    service.waitUntilFlushed(INDEX_NAME, REGION_NAME, 60000, TimeUnit.MILLISECONDS);

    System.out.println("NABA :Postwait Queued events:" + aeq.getStatistics().getEventsQueued());

    for(int i = 0; i < 1000; i++) {
      aeq = (AsyncEventQueueImpl) getCache().getAsyncEventQueue(aeqId);
      System.out.println("NABA :: " +aeq + "NABA :: ID " +aeqId);
      LuceneQuery<Integer, Type1>
          query =
          service.createLuceneQueryFactory().setLimit(Integer.MAX_VALUE).create(INDEX_NAME,
              REGION_NAME, "value*", LuceneService.REGION_VALUE_FIELD);
      PageableLuceneQueryResults<Integer, Type1> results = query.findPages();
      System.out.println("NABA :Queued events:" + aeq.getStatistics().getEventsQueued());
      System.out.println("NABA :::" + results.size());

    }

    for(int i = 0; i < 10010; i++) {
      getCache().getRegion(REGION_NAME).put("key" + i, "value" + i);
    }


//    LuceneQuery<Integer, Type1>
//        query =
//        service.createLuceneQueryFactory().setLimit(Integer.MAX_VALUE).create(INDEX_NAME,
//            REGION_NAME, "value*", LuceneService.REGION_VALUE_FIELD);
//
//    PageableLuceneQueryResults<Integer, Type1> results = query.findPages();
//    Assert.assertEquals(1, results.size());
  }


  private CompletableFuture<Void> createRegionAsync(VM dataStore1) {
    CompletableFuture<Void>
        createFuture1 =
        CompletableFuture
            .runAsync(
                () -> createRegion(dataStore1, RegionShortcut.PARTITION_REDUNDANT_PERSISTENT));
    return createFuture1;
  }

  private void createRegion(VM vm, RegionShortcut partitionPersistent) {
    vm.invoke(() -> {
      LuceneService service = LuceneServiceProvider.get(getCache());
      service.createIndexFactory().setFields(LuceneService.REGION_VALUE_FIELD).create(INDEX_NAME, REGION_NAME);

      RegionFactory<String, Type1> regionFactory =
          getCache().createRegionFactory(partitionPersistent);

      regionFactory.setPartitionAttributes(new PartitionAttributesFactory().setTotalNumBuckets(1).create());
      regionFactory.create(REGION_NAME);
      service.getIndex(INDEX_NAME, REGION_NAME);
    });
  }
}
