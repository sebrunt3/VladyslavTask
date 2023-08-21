@IsTest
private class AccountOwnersSharingHandlerTest {
    @TestSetup
    static void setupTestData() {
        Account accounts = new Account(Name = 'AccountTest1', OwnerId = UserInfo.getUserId());
        insert accounts;

        List<Contact> contacts = new List<Contact>{
                new Contact(LastName = 'ContactTest1', RelatedAccountOwner__c = UserInfo.getUserId()),
                new Contact(LastName = 'ContactTest2')
        };
        insert contacts;

        List<AccountContactRelationship__c> relationships = new List<AccountContactRelationship__c>{
                new AccountContactRelationship__c(ContactId__c = contacts[0].Id, AccountId__c = accounts.Id)
        };
        insert relationships;
    }

    @IsTest
    static void afterInsertSharingOwnersTest() {
        User userStandardTest = createDefaultUser('standarduserForTest@testorg.com', 'Standard User');
        Account account = insertNewRelationship(userStandardTest.Id);

        Test.startTest();
        AccountOwnersSharingHandler.afterInsertSharingOwners(new Map<Id, Account>(new List<Account>{account}));
        Test.stopTest();

        List<Contact> contactProcessedList = [SELECT Id, RelatedAccountOwner__c FROM Contact ORDER BY LastName ASC];
        Set<String> relatedAccountOwnersSetProcessed1 = new Set<String>(contactProcessedList[0].RelatedAccountOwner__c.split(','));
        Set<String> relatedAccountOwnersSetProcessed2 = new Set<String>(contactProcessedList[1].RelatedAccountOwner__c.split(','));

        Assert.isTrue(relatedAccountOwnersSetProcessed1.contains(userStandardTest.Id), 'Set of Ids should have new Id after Insert Handler was running');
        Assert.isTrue(relatedAccountOwnersSetProcessed2.contains(userStandardTest.Id), 'Set of Ids should have new Id after Insert Handler was running');
    }

    @IsTest
    static void afterUpdateSharingOwnersTest() {
        User userStandardTest = createDefaultUser('standarduserForTest@testorg.com', 'Standard User');
        Account account = [SELECT Id, OwnerId FROM Account WHERE Name = 'AccountTest1' LIMIT 1];

        Test.startTest();
        account.OwnerId = userStandardTest.Id;
        update account;
        Test.stopTest();

        List<Contact> contactProcessedList = [SELECT Id, RelatedAccountOwner__c FROM Contact ORDER BY LastName ASC];
        Set<String> relatedAccountOwnersSetModified = new Set<String>(contactProcessedList[0].RelatedAccountOwner__c.split(','));

        Assert.isTrue(relatedAccountOwnersSetModified.contains(userStandardTest.Id), 'Set of Ids should have new Id after Update Handler was running');
        Assert.isFalse(relatedAccountOwnersSetModified.contains(UserInfo.getUserId()), 'Set of Ids should not have old Id after Update Handler was running');
        Assert.isTrue(String.isBlank(contactProcessedList[1].RelatedAccountOwner__c), 'Set of Ids should have been empty after Update Handler was running');
    }

    @IsTest
    static void beforeDeleteSharingOwnersTest() {
        Account account = [SELECT Id, OwnerId FROM Account WHERE Name = 'AccountTest1' LIMIT 1];

        Test.startTest();
        delete account;
        Test.stopTest();

        List<Contact> contactProcessedList = [SELECT Id, RelatedAccountOwner__c FROM Contact ORDER BY LastName ASC];

        Assert.isTrue(String.isBlank(contactProcessedList[0].RelatedAccountOwner__c), 'Set of Ids should have been empty after Delete Handler was running');
        Assert.isTrue(String.isBlank(contactProcessedList[1].RelatedAccountOwner__c), 'Set of Ids should have still been empty after Delete Handler was running');
    }

    @IsTest
    static void beforeDeleteHasDuplicateOwnersTest() {
        Account account = insertNewRelationship(UserInfo.getUserId());
        Contact contact = [SELECT Id, RelatedAccountOwner__c FROM Contact WHERE LastName = 'ContactTest2' LIMIT 1];
        contact.RelatedAccountOwner__c = UserInfo.getUserId();
        update contact;
        Account accountRemoved = [SELECT Id, OwnerId FROM Account WHERE Name = 'AccountTest1' LIMIT 1];

        Test.startTest();
        delete accountRemoved;
        Test.stopTest();

        List<Contact> contactProcessedList = [SELECT Id, RelatedAccountOwner__c FROM Contact ORDER BY LastName ASC];
        Set<String> relatedAccountOwnersSetModified1 = new Set<String>(contactProcessedList[0].RelatedAccountOwner__c.split(','));
        Set<String> relatedAccountOwnersSetModified2 = new Set<String>(contactProcessedList[1].RelatedAccountOwner__c.split(','));

        Assert.isTrue(relatedAccountOwnersSetModified1.contains(UserInfo.getUserId()), 'Set of Ids should have still duplicate OwnerId after Delete Handler was running');
        Assert.isTrue(relatedAccountOwnersSetModified2.contains(UserInfo.getUserId()), 'Set of Ids should have still duplicate OwnerId after Delete Handler was running');
    }

    private static User createDefaultUser(String userName, String profileName) {
        Profile profile = [SELECT Id FROM Profile WHERE Name = :profileName];
        User user = new User(
                Alias = 'standt',
                Email = 'standarduser@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = profile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = userName,
                IsActive = true
        );
        insert user;

        return user;
    }

    private static Account insertNewRelationship(Id userId) {
        Account account = new Account(Name = 'AccountTest3', OwnerId = userId);
        insert account;
        List<Contact> contactList = [SELECT Id, RelatedAccountOwner__c FROM Contact ORDER BY LastName ASC];
        List<AccountContactRelationship__c> relationships = new List<AccountContactRelationship__c>{
                new AccountContactRelationship__c(ContactId__c = contactList[0].Id, AccountId__c = account.Id),
                new AccountContactRelationship__c(ContactId__c = contactList[1].Id, AccountId__c = account.Id)
        };
        insert relationships;

        return account;
    }
}