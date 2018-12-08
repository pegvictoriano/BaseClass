@isTest
private class TriggerDispatcherTest {

	static testMethod void publicMethodsTest() {
		TestTB stub = new TestTB();
		TriggerDispatcher.bypassedHandlers = new Set<String>();
		System.assertNotEquals(null, TriggerDispatcher.loopCountMap);
		TriggerDispatcher.setMaxLoopCount('TestTB', 5);
		TriggerDispatcher.setMaxLoopCount('TestTB', 6);
		System.assertNotEquals(null, TriggerDispatcher.bypassedHandlers);
		TriggerDispatcher.clearMaxLoopCount('TestTB');
		TriggerDispatcher.bypass('TestTB');
		stub.setTriggerContext('before insert', true);
		TriggerDispatcher.run(stub);
		System.assertEquals(true, TriggerDispatcher.isBypassed('TestTB'));
		TriggerDispatcher.clearBypass('TestTB');
		TriggerDispatcher.clearAllBypasses();
	}
	static testMethod void loopMethodsTest() {
		TestTB stub = new TestTB();
		TriggerDispatcher.setMaxLoopCount('TestTB', 6);
		TriggerDispatcher.setMaxLoopCount('TestTB', 1);
		try {
			TriggerDispatcher.run(stub);
		} catch (Exception e) {
			System.assertNotEquals(null, e);
		}
		try {
			TriggerDispatcher.addToLoopCount('TestTB');
		} catch (Exception e) {
			System.assertNotEquals(null, e);
		}
		//
		TriggerDispatcher.LoopCount lc = new TriggerDispatcher.LoopCount();
		System.assertEquals(5,lc.getMax());
		System.assertEquals(0,lc.getCount());
		lc = new TriggerDispatcher.LoopCount(1);
		System.assertEquals(false,lc.increment());
		lc = new TriggerDispatcher.LoopCount(-1);
		System.assertEquals(false,lc.exceeded());
	}
	static testMethod void runMethodsTest() {
		try {
			TriggerDispatcher.run(null);
		} catch (Exception e) {
			System.assertEquals('Handler exception', e.getMessage());
		}
		TestTB handler = new TestTB();

		handler.setTriggerContext('before insert', true);
		TriggerDispatcher.run(handler);
		handler.setTriggerContext('before update', true);
		TriggerDispatcher.run(handler);
		handler.setTriggerContext('before delete', true);
		TriggerDispatcher.run(handler);
		handler.setTriggerContext('after insert', true);
		TriggerDispatcher.run(handler);
		handler.setTriggerContext('after update', true);
		TriggerDispatcher.run(handler);
		handler.setTriggerContext('after delete', true);
		TriggerDispatcher.run(handler);
		handler.setTriggerContext('after undelete', true);
		TriggerDispatcher.run(handler);
	}
	static testMethod void baseMethodsTest() {
		TestTB stub = new TestTB();
		System.assertEquals(null, stub.records);
		System.assertEquals(null, stub.oldRecords);
		System.assertEquals(null, stub.newMap);
		System.assertEquals(null, stub.oldMap);
	}
	public class TestTB extends TriggerBase implements ITriggerBase {
		public TestTB() { }
	}
}