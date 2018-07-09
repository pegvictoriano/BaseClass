@isTest
public class TestDataFactory extends BaseClass {
  //Private Constructor
  private TestDataFactory() {
    super(new List<Schema.sObjectType> {
      Account.sObjectType,
      Contact.sObjectType
    });
  }
  //To do methods
  public TestDataFactory createAccount(Integer recCount) {
    for (Integer i = 0; i < recCount; i++) {
      Account acc = new Account();
      acc.Name = 'TestDataAccount' + i;
      push(acc);
    }

    return instance;
  }
  public TestDataFactory createAccountwithContact(Integer recCount, Integer recCountContact) {
    for (Integer i = 0; i < recCount; i++) {
      Account acc = new Account();
      acc.Name = 'TestDataAccount' + i;
      push(acc);

      for (Integer j = 0; j < recCountContact; j++) {
        Contact con = new Contact();
        con.Email = String.format('Test{0}@test.com', new LIST<String> {'' + j});
        con.FirstName = 'TestDataFirstName';
        con.LastName = 'TestLastName' + j;
        push(con, Contact.AccountId, acc);
      }
    }

    return instance;
  }

  /**
   * Singleton Instance of Class
   */
  static TestDataFactory instance;
  public static TestDataFactory getInstance() {
    if (instance == null) {
      instance = new TestDataFactory();
    }

    return instance;
  }
}