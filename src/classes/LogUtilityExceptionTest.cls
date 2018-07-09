@isTest
private class LogUtilityExceptionTest {

	@testSetup static void setupDataTest() {
		//No set up data
	}

	static testMethod void debugmethodTest() {
		Test.startTest();
		LogUtilityException.logDebug('Test', 'Test', 'Test');
		Test.stopTest();
		System.assertEquals(1, [SELECT count() FROM Log__c], 'Test Log count');
	}
	static testMethod void errormethodTest() {
		Test.startTest();
		LogUtilityException.logExceptionMSG('Test', 'Test', 'Test');
		Test.stopTest();
		System.assertEquals(1, [SELECT count() FROM Log__c], 'Test Log count');
	}
	static testMethod void exceptionmethodTest() {
		Test.startTest();
		List<Account> lacc = new List<Account>();
		try {
			lacc.add(new Account());
			insert lacc;
		} catch (Exception e) {
			LogUtilityException.logException(e);
		}
		Test.stopTest();
		System.assertEquals(1, [SELECT count() FROM Log__c], 'Test Log count');
	}
	static testMethod void exceptionmethodListTest() {
		Test.startTest();
		List<Account> lacc = new List<Account>();
		try {
			lacc.add(new Account());
			insert lacc;
		} catch (Exception e) {
			LogUtilityException.logException(e, lacc);
		}
		Test.stopTest();
		System.assertEquals(1, [SELECT count() FROM Log__c], 'Test Log count');
	}
	static testMethod void commitRecordmethodTest() {
		BaseClass bc = new BaseClass(
		new List<Schema.sObjectType> {
			Account.sObjectType
		});
		Test.startTest();
		Account nAcc = new Account();
		bc.push(nAcc);
		LogUtilityException.logCommitRecords(
		    bc.commitRecordsPartial()
		);
		Test.stopTest();
		//REQUIRED_FIELD_MISSING does not create log
		System.assertEquals(0, [SELECT count() FROM Log__c], 'Test Log count');
	}
	static testMethod void exceptionValidationMethodTest() {
		Test.startTest();
		try {
			testAccountValidationException();
		} catch (Exception ex) {
			System.assertEquals('LogUtilityException', ex.getTypeName());
		}
		Test.stopTest();
		System.assertNotEquals(null, [SELECT Id FROM Log__c], 'Test Log count');
	}
	static testMethod void exceptionValidationThrowTest() {
		Test.startTest();
		try {
			LogUtilityException.throwMSG();

		} catch (Exception ex) {
			System.assertEquals('LogUtilityException', ex.getTypeName());
		}
		Test.stopTest();
	}
	static void testAccountValidationException() {
		try {
			Account acc = new Account();
			insert acc;
		} catch (Exception e) {
			LogUtilityException.logException(e);
		}
	}
}