@IsTest
private class HierarchyUtilsTest {

    @TestSetup
    static void init() {
        createSimpleHierarchy();
    }

    static void createSimpleHierarchy() {

        Account accountLevel1 = new Account(Name = 'A1');
        insert accountLevel1;


        List<Account> accountsLevel2 = new List<Account>{
                new Account(Name = 'A2', ParentId = accountLevel1.Id),
                new Account(Name = 'A3', ParentId = accountLevel1.Id)
        };
        insert accountsLevel2;

        List<Account> accountsLevel3 = new List<Account>{
                new Account(Name = 'A4', ParentId = accountsLevel2.get(1).Id),
                new Account(Name = 'A5', ParentId = accountsLevel2.get(1).Id)
        };
        insert accountsLevel3;
    }

    @IsTest
    static void testGetPathUp() {

        List<Id> accountIds = new List<Id>{
                getAccountIdByName('A5'),
                getAccountIdByName('A1')
        };

        Test.startTest();

        HierarchyUtils hUtils = HierarchyUtils.getInstance(Account.SObjectType, Account.fields.ParentId);
        hUtils.clear();

        Map<Id, List<Id>> pathUpMap = hUtils.getPathUp(accountIds);

        System.assertEquals(pathUpMap.get(accountIds.get(0)).size(), 2);
        System.assertEquals(pathUpMap.get(accountIds.get(1)).size(), 0);

        Test.stopTest();
    }

    @IsTest
    static void testGetAllChildIds() {

        List<Id> accountIds = new List<Id>{
                getAccountIdByName('A5'),
                getAccountIdByName('A1')
        };

        Test.startTest();

        HierarchyUtils hUtils = HierarchyUtils.getInstance(Account.SObjectType, Account.fields.ParentId);
        hUtils.clear();

        Map<Id, List<Id>> allChildIds = hUtils.getAllChildIds(accountIds);

        System.assertEquals(allChildIds.get(accountIds.get(0)).size(), 0);
        System.assertEquals(allChildIds.get(accountIds.get(1)).size(), 4);

        Test.stopTest();
    }

    static Id getAccountIdByName(String accountName) {
        List<Account> accountItems = [SELECT Id FROM Account WHERE Name = :accountName LIMIT 1];
        return (!accountItems.isEmpty()) ? accountItems.get(0).Id : null;
    }
}