@isTest
private class BaseClass_Test {
	@TestSetup
	static void initData() {
		insert new Account(Name = 'TestAccount');
		insert new Contact(Email = 'contact@test.com', LastName = 'lastname');
	}
	/**
	 * Test Sample
	 */
	static testMethod void testRecordsmethodInsert() {
		List<Account> lAccounts = new List<Account>();

		for (Integer i = 0; i < ; i++) {

		}
		Test.startTest();
		BaseClass bc = new BaseClass();
		bc.initialize(new List<Schema.sObjectType> {
			Account.sObjectType,
			Contact.sObjectType
		});
		Account oAccount = new Account(
		    Name = 'TestAccount'
		);
		bc.push(oAccount);
		Contact oCon = new Contact(
		    Email = 'Test@test.com',
		    FirstName = 'TestFirstName',
		    LastName = 'TestLastName'
		);
		bc.push(oCon,
		        Contact.AccountId,
		        oAccount);
		System.assertNotEquals(0, bc.getRecordsByType(Account.sObjectType).size());
		System.assertNotEquals(0, bc.getRecordsByType(Contact.sObjectType).size());
		bc.commitRecords();
		Test.stopTest();
		List<Contact> contacts = [Select Id, AccountId FROM Contact WHERE Email = 'Test@test.com'];
		System.assertNotEquals(0, contacts.size());
		System.assertNotEquals(null, contacts.get(0).AccountId);
	}
	static testMethod void testRecordsmethodUpdate() {
		Test.startTest();
		BaseClass bc = new BaseClass(new List<Schema.sObjectType> {
			Account.sObjectType,
			Contact.sObjectType
		});
		List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = 'TestAccount'];
		Account oAccount;

		if (!accounts.isEmpty()) {
			oAccount = accounts.get(0);
		}

		oAccount.Name = 'TestAccount1';
		bc.push(oAccount);
		List<Contact> contacts = [SELECT Id, Name FROM Contact WHERE Email = 'contact@test.com'];
		Contact oCon;

		if (!contacts.isEmpty()) {
			oCon = contacts.get(0);
		}

		bc.push(oCon,
		        Contact.AccountId,
		        oAccount);
		System.assertNotEquals(0, bc.getRecordsByType(Account.sObjectType).size());
		System.assertNotEquals(0, bc.getRecordsByType(Contact.sObjectType).size());
		bc.commitRecords();
		Test.stopTest();
		List<Contact> contactslist = [Select Id, AccountId FROM Contact WHERE Email = 'contact@test.com'];
		System.assertNotEquals(0, contactslist.size());
		System.assertNotEquals(null, contactslist.get(0).AccountId);
	}
	static testMethod void testRecordsmethodRelate() {
		Test.startTest();
		BaseClass bc = new BaseClass(new List<Schema.sObjectType> {
			Account.sObjectType,
			Contact.sObjectType,
			Case.sObjectType
		});
		List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = 'TestAccount'];
		Account oAccount;

		if (!accounts.isEmpty()) {
			oAccount = accounts.get(0);
		}

		oAccount.Name = 'TestAccount1';
		bc.push(oAccount);
		List<Contact> contacts = [SELECT Id, Name FROM Contact WHERE Email = 'contact@test.com'];
		Contact oCon;

		if (!contacts.isEmpty()) {
			oCon = contacts.get(0);
		}

		bc.push(oCon,
		        Contact.AccountId,
		        oAccount);
		Case oCase = new Case();
		oCase.Status = 'New';
		oCase.Origin = 'Web';
		bc.push(oCase, Case.AccountId, oAccount);
		//Add relation
		bc.relate(oCase, Case.ContactId, oCon);
		//
		bc.commitRecords();
		Test.stopTest();
		List<Case> caseList = [Select Id, AccountId, ContactId FROM Case];
		System.assertNotEquals(0, caseList.size());
		System.assertNotEquals(null, caseList.get(0).AccountId);
		System.assertNotEquals(null, caseList.get(0).ContactId);
	}
	static testMethod void testRecordsmethodPartialCommit() {
		Test.startTest();
		BaseClass bc = new BaseClass(new List<Schema.sObjectType> {
			Account.sObjectType,
			Contact.sObjectType
		});
		List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = 'TestAccount'];
		Account oAccount;

		if (!accounts.isEmpty()) {
			oAccount = accounts.get(0);
		}

		oAccount.Name = null;
		bc.push(oAccount);
		Contact oCon = new Contact();
		oCon.LastName = null;
		bc.push(oCon,
		        Contact.AccountId,
		        oAccount);
		List<BaseClass.CommitRecord> lErrors = bc.commitRecordsPartial();
		System.assert(lErrors.size() > 0);

		for (BaseClass.CommitRecord err : lErrors) {
			//Test if Error Records are not null
			System.assertNotEquals(null, err.record);
		}

		bc.pop(oAccount);
		List<BaseClass.CommitRecord> lErrorsDel = bc.commitRecordsPartial();
		//
		Test.stopTest();
	}
	static testMethod void testRecordsmethodPartialCommit2() {
		Test.startTest();
		BaseClass bc = new BaseClass(new List<Schema.sObjectType> {
			Account.sObjectType,
			Contact.sObjectType
		});
		List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = 'TestAccount'];
		Account oAccount;

		if (!accounts.isEmpty()) {
			oAccount = accounts.get(0);
		}

		oAccount.Name = null;
		bc.push(oAccount);
		Contact oCon = new Contact();
		oCon.LastName = null;
		bc.push(oCon,
		        Contact.AccountId,
		        oAccount);
		List<BaseClass.CommitRecord> lErrors = bc.commitRecordsPartial(true);
		System.assert(lErrors.size() > 0);

		for (BaseClass.CommitRecord err : lErrors) {
			//Test if Error Records are not null
			System.assertNotEquals(null, err.record);
		}

		bc.pop(oAccount);
		List<BaseClass.CommitRecord> lErrorsDel = bc.commitRecordsPartial(true);
		//
		Test.stopTest();
	}
	static testMethod void testRecordsmethodDelete() {
		Test.startTest();
		BaseClass bc = new BaseClass();
		bc.initialize(new List<Schema.sObjectType> {
			Account.sObjectType,
			Contact.sObjectType
		});
		List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = 'TestAccount'];
		Account oAccount;

		if (!accounts.isEmpty()) {
			oAccount = accounts.get(0);
		}

		bc.pop(new List<Account> {oAccount});
		bc.commitRecords();
		Test.stopTest();
		List<Account> contacts = [Select Id FROM Account where Name = 'TestAccount'];
		System.assertEquals(0, contacts.size());
	}
	static testMethod void testRecordsmethodDeletePartial() {
		List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = 'TestAccount'];
		Account oAccount;

		if (!accounts.isEmpty()) {
			oAccount = accounts.get(0);
		}

		delete oAccount;
		//
		Test.startTest();
		BaseClass bc = new BaseClass();
		bc.initialize(new List<Schema.sObjectType> {
			Account.sObjectType,
			Contact.sObjectType
		});
		bc.pop(oAccount);
		List<BaseClass.CommitRecord> lErrors = bc.commitRecordsPartial();
		System.assert(lErrors.size() > 0);
		Test.stopTest();
	}
	static testMethod void testRecordsmethodDeletePartial2() {
		List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = 'TestAccount'];
		Account oAccount;

		if (!accounts.isEmpty()) {
			oAccount = accounts.get(0);
		}

		delete oAccount;
		//
		Test.startTest();
		BaseClass bc = new BaseClass();
		bc.initialize(new List<Schema.sObjectType> {
			Account.sObjectType,
			Contact.sObjectType
		});
		bc.pop(oAccount);
		List<BaseClass.CommitRecord> lErrors = bc.commitRecordsPartial(true);
		System.assert(lErrors.size() > 0);
		Test.stopTest();
	}
	static testMethod void testRecordsmethodNotTyped() {
		Test.startTest();
		BaseClass bc = new BaseClass();
		BaseClass bc2 = new BaseClass();
		bc.initialize(new List<Schema.sObjectType> {
			Account.sObjectType,
			Contact.sObjectType
		});

		try {
			bc.push(new Task());
			bc.commitRecords();
		} catch (BaseClass.BaseClassException ex) {
			System.assert(String.isNotBlank(ex.getMessage()));
		}

		try {
			bc2.push(new Account(Name = 'Test'));
			bc2.commitRecords();
		} catch (BaseClass.BaseClassException ex) {
			System.assert(String.isNotBlank(ex.getMessage()));
		}

		Test.stopTest();
	}
	static testMethod void testcommitRecordsNegative() {
		BaseClass bc = new BaseClass(new List<Schema.sObjectType> {
			Contact.sObjectType
		});

		try {
			bc.commitOrderList = null;
			bc.commitRecords();
		} catch (BaseClass.BaseClassException ex) {
			System.assertNotEquals(null, ex.getMessage());
		}
	}
	static testMethod void testinstantiateNegative() {
		BaseClass bc = new BaseClass(new List<Schema.sObjectType> {
			Contact.sObjectType
		});

		try {
			bc.lCommitOrder = null;
			bc.instantiate();
		} catch (BaseClass.BaseClassException ex) {
			System.assertNotEquals(null, ex.getMessage());
		}
	}
	static testMethod void testRecordsNegative() {
		try {
			BaseClass.Record rec = new BaseClass.Record();
			rec.record = new Contact();
			rec.relatedField = Contact.AccountId;
			rec.parentRecord = new Account();
			rec.createRelation();
			BaseClass.CommitRecord err = new BaseClass.CommitRecord(new Account(), null, true);
			System.assertEquals(true, err.getIsUpdate());
		} catch (BaseClass.BaseClassException ex) {
			System.assertNotEquals(null, ex.getMessage());
		}
	}
	static testMethod void bulkInsertAccoount300() {
		TestDataFactory.getInstance().createAccount(300).commitRecords();
		System.assertEquals(300,
		                    [SELECT count() FROM Account WHERE Name LIKE 'TestDataAccount%']);
	}
	static testMethod void bulkInsertAccoount300andContact10() {
		TestDataFactory.getInstance().createAccountwithContact(300, 10).commitRecords();
		System.assertEquals(300,
		                    [SELECT count() FROM Account WHERE Name LIKE 'TestDataAccount%']);
		System.assertEquals(3000,
		                    [SELECT count() FROM Contact WHERE FirstName LIKE 'TestDataFirstName%']);
	}
}