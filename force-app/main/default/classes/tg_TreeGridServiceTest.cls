@isTest
public class tg_TreeGridServiceTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Tree_Grid_Configuration__c records
        List<Tree_Grid_Configuration__c> configurations = new List<Tree_Grid_Configuration__c>();
        
        Tree_Grid_Configuration__c dataTableConfig = new Tree_Grid_Configuration__c(
            Name = 'Account DataTable 01',
            Type__c = 'Data-Table',
            Current_Table_Object_Api_Name__c = 'Account',
            Dynamic_SOQL__c = 'SELECT Id, Name, Type, AnnualRevenue, ' +
                               '(SELECT Id, Name, BirthDate FROM Contacts) FROM Account LIMIT 5',
            Child_Object_Relationship_Name__c = 'Contacts',
            Is_Records_Editable__c = true,
            Current_Table_Object_Label__c = 'Account',
            Is_Records_Deletable__c = true,
            Child_Table_Name__c = 'Contact DataTable 01',
            Is_Child_Record_Creatable__c = true,
            Table_Header_Row_CSS__c = 'header-css',
            Table_CSS__c = 'table-css',
            Table_Record_Row_CSS__c = 'record-css',
            Mobile_Form_Table_Vertical_Spacing__c = '10px'
        );
        insert dataTableConfig;
        
          Tree_Grid_Configuration__c childDataTableConfig = new Tree_Grid_Configuration__c(
            Name = 'Contact DataTable 01',
            Type__c = 'Data-Table',
            Current_Table_Object_Label__c = 'Contact',
            Current_Table_Object_Api_Name__c = 'Contact',
            Dynamic_SOQL__c = 'SELECT Id, Name, Type, AnnualRevenue, ' +
                               '(SELECT Id, Name, BirthDate FROM Contacts) FROM Account LIMIT 1',
            Child_Object_Relationship_Name__c = '',
            Is_Records_Editable__c = true,
            Is_Records_Deletable__c = true,
            Child_Table_Name__c = '',
            Is_Child_Record_Creatable__c = true,
            Table_Header_Row_CSS__c = 'header-css',
            Table_CSS__c = 'table-css',
            Table_Record_Row_CSS__c = 'record-css',
            Mobile_Form_Table_Vertical_Spacing__c = '10px'
        );
        insert childDataTableConfig;

        // Field Configuration
        Tree_Grid_Configuration__c fieldConfig = new Tree_Grid_Configuration__c(
            Name = 'Account DataTable 01',
            Type__c = 'Field',
            Is_Active__c = true,
            Data_Type__c = 'text',
            Mobile_Form_Factor_Width__c = 12,
            Tab_Form_Factor_Width__c = 6,
            Desktop_Form_Factor_Width__c = 4,
            Field_Label__c = 'Name',
            Field_API_Name__c = 'Name',
            Is_Required__c = true,
            Is_Sortable__c = true,
            Is_Disabled__c = false,
            Link_Href__c = '/recordId',
            Asc_Desc_Arrow_Variant__c = 'inverse'
        );
        insert fieldConfig;
        
        Tree_Grid_Configuration__c childFieldConfig = new Tree_Grid_Configuration__c(
            Name = 'Contact DataTable 01',
            Type__c = 'Field',
            Is_Active__c = true,
            Data_Type__c = 'text',
            Mobile_Form_Factor_Width__c = 12,
            Tab_Form_Factor_Width__c = 6,
            Desktop_Form_Factor_Width__c = 4,
            Field_Label__c = 'Name',
            Field_API_Name__c = 'Name',
            Is_Required__c = true,
            Is_Sortable__c = true,
            Is_Disabled__c = false,
            Link_Href__c = '/recordId',
            Asc_Desc_Arrow_Variant__c = 'inverse'
        );
        insert childFieldConfig;

        
        // Create test records
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Test Account 1'),
            new Account(Name = 'Test Account 2')
        };
        insert accounts;

        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Test', LastName = 'Contact 1', AccountId = accounts[0].Id),
            new Contact(FirstName = 'Test', LastName = 'Contact 2', AccountId = accounts[1].Id)
        };
        insert contacts;
    }

     @isTest
    static void testDeleteRecords() {
        // Step 1: Create test data
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;

        // Step 2: Prepare data for the method
        List<Map<String, Object>> sObjectRecords = new List<Map<String, Object>>();
        for (Account acc : accounts) {
            Map<String, Object> recordMap = new Map<String, Object>();
            recordMap.put('Id', acc.Id);
            sObjectRecords.add(recordMap);
        }

        // Step 3: Call the deleteRecords method
        Test.startTest();
        tg_TreeGridService.deleteRecords(sObjectRecords, 'Account');
        Test.stopTest();

        // Step 4: Verify the records are deleted
        List<Account> deletedAccounts = [SELECT Id FROM Account WHERE Id IN :accounts];
        System.assertEquals(0, deletedAccounts.size(), 'All accounts should be deleted.');
    }

    @isTest
    static void testGetBluePrintOfTable() {
        Test.startTest();
        tg_SObjectBuilder.testCoverage();
        // Call the method
        Map<String, tg_TreeGridService.TreeGridResponse> response = tg_TreeGridService.getBluePrintOfTable('Account DataTable 01');
        
        // Validate the response
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assert(response.containsKey('Account'), 'Blueprint should contain Account table configuration');
        tg_TreeGridService.TreeGridResponse parentResponse = response.get('Account');        
        Test.stopTest();
    }

    @isTest
    static void testGetTreeGridData() {
        Test.startTest();
        
        // Call the method
        tg_TreeGridService.TreeGridResponse response = tg_TreeGridService.getTreeGridData('Account DataTable 01', null);
        
        // Validate the response
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assert(response.records.size() > 0, 'Records should be available');
        System.assertEquals('Account', response.objectApiName, 'Object API Name mismatch');
        
        Test.stopTest();
    }

    @isTest
    static void testUpsertRecords() {
        Test.startTest();
        
        // Create a record map
        Map<String, Object> recordData = new Map<String, Object>{
            'Name' => 'New Test Account'
        };
        
        // Call the upsert method
        String recordId = tg_TreeGridService.upsertRecords('Account', recordData, null);
        
        // Validate the result
        System.assertNotEquals(null, recordId, 'Upsert should return a record ID');
        Account account = [SELECT Id, Name FROM Account WHERE Id = :recordId];
        System.assertEquals('New Test Account', account.Name, 'Account Name mismatch');
        
        Test.stopTest();
    }
    
}