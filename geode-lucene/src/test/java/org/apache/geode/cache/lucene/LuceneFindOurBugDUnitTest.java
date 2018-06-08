package org.apache.geode.cache.lucene;

import static org.apache.geode.cache.lucene.test.LuceneTestUtilities.DEFAULT_FIELD;
import static org.apache.geode.cache.lucene.test.LuceneTestUtilities.INDEX_NAME;
import static org.apache.geode.cache.lucene.test.LuceneTestUtilities.REGION_NAME;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;

import org.junit.Assert;
import org.junit.Test;

import org.apache.geode.cache.PartitionedRegionStorageException;
import org.apache.geode.cache.RegionFactory;
import org.apache.geode.cache.RegionShortcut;
import org.apache.geode.cache.lucene.internal.repository.serializer.Type1;
import org.apache.geode.cache.lucene.test.LuceneTestUtilities;
import org.apache.geode.cache.lucene.test.TestObject;
import org.apache.geode.test.dunit.VM;

public class LuceneFindOurBugDUnitTest extends LuceneDUnitTest {

  @Test
  public void test() throws ExecutionException, InterruptedException {
    //Create region and index on two members
    createRegion(dataStore1, RegionShortcut.PARTITION_PERSISTENT);

    createRegion(dataStore2, RegionShortcut.PARTITION_PROXY);

    //Pause the queue
    dataStore1.invoke(() -> LuceneTestUtilities.pauseSender(getCache()));

    //Put some data in the region
    dataStore2.invoke(() -> {
      getCache().getRegion(REGION_NAME).put("key", "value");
    });

    //Shutdown one member
    dataStore1.invoke(() -> getCache().close());


    //TODO - do this in parallel
    CompletableFuture<Void>
        createFuture =
        CompletableFuture
            .runAsync(() -> createRegion(dataStore1, RegionShortcut.PARTITION_PERSISTENT));

    try {
      dataStore2.invoke(() -> {
        while(true) {
          try {
            LuceneService service = LuceneServiceProvider.get(getCache());
            service.waitUntilFlushed(INDEX_NAME, REGION_NAME, 60000, TimeUnit.MILLISECONDS);

            LuceneQuery<Integer, Type1>
                query =
                service.createLuceneQueryFactory().create(INDEX_NAME,
                    REGION_NAME, "value", LuceneService.REGION_VALUE_FIELD);

            PageableLuceneQueryResults<Integer, Type1> results = query.findPages();
            Assert.assertEquals(1, results.size());
            break;
          } catch (PartitionedRegionStorageException e) {
            System.out.println("Hit expected exception: " + e.getMessage());
          }
        }
      });
    } finally {
      createFuture.get();
    }


  }

  private void createRegion(VM vm, RegionShortcut partitionPersistent) {
    vm.invoke(() -> {
      LuceneService service = LuceneServiceProvider.get(getCache());
      service.createIndexFactory().setFields(LuceneService.REGION_VALUE_FIELD).create(INDEX_NAME, REGION_NAME);

      RegionFactory<String, Type1> regionFactory =
          getCache().createRegionFactory(partitionPersistent);

      regionFactory.create(REGION_NAME);
      service.getIndex(INDEX_NAME, REGION_NAME);
    });
  }
}
