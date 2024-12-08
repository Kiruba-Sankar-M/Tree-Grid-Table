 public without sharing class tg_TreeGridService {
    private static Map<String, Tree_Grid_Configuration__c> dataTableConfigMap = new Map<String, Tree_Grid_Configuration__c>();
    private static Map<String, List<Tree_Grid_Configuration__c>> fieldConfigMap = new Map<String, List<Tree_Grid_Configuration__c>>();
    private static Map<String, TreeGridResponse> tableConfigBluePrint = new Map<String, TreeGridResponse>();

    public class TreeGridResponse {
        @AuraEnabled public Boolean isRecordsEditable { get; set; }
        @AuraEnabled public Boolean isRecordActionAvailable { get; set; }
        @AuraEnabled public Boolean isChildRecordCreatable { get; set; }
        @AuraEnabled public String parentLookupFieldApiName { get; set; }
        @AuraEnabled public Boolean isRecordsAvailable { get; set; }
        @AuraEnabled public Boolean isRecordsDeletable { get; set; }
        @AuraEnabled public String currentTableObjectLabel { get; set; }
        @AuraEnabled public String childObjectApiName { get; set; }
        @AuraEnabled public String childTableObjectLabel { get; set; }
        @AuraEnabled public String tableHeaderRowCss { get; set; }
        @AuraEnabled public String tableRecordRowCss { get; set; }
        @AuraEnabled public String objectApiName { get; set; }
        @AuraEnabled public String tableBodyCss { get; set; }
        @AuraEnabled public String mobileFormVerticalSpacing { get; set; }
        @AuraEnabled public List<Column> columns { get; set; } 
        @AuraEnabled public List<Record> records { get; set; } 

        public TreeGridResponse() {
            columns = new List<Column>();
            records = new List<Record>();
            isRecordsAvailable = false;
        }
    }

    public class Column {
        @AuraEnabled public String fieldApiName { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String ascDescArrowVariant { get; set; }
        @AuraEnabled public Boolean isSortable { get; set; }
    }

    public class Record {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public Boolean isExpanded { get; set; }
        @AuraEnabled public Boolean isActive { get; set; } 
        @AuraEnabled public List<Field> fields { get; set; }
        @AuraEnabled public TreeGridResponse childRecords { get; set; }

        public Record() {
            isExpanded = false;
            isActive = false;
            fields = new List<Field>();
        }
    }

    public class Field {
        @AuraEnabled public Boolean isFirstColumn { get; set; }
        @AuraEnabled public String fieldApiName { get; set; }
        @AuraEnabled public Object value { get; set; }
        @AuraEnabled public Boolean isRequired { get; set; }
        @AuraEnabled public String linkHref { get; set; }
        @AuraEnabled public Boolean isActive { get; set; }
        @AuraEnabled public Boolean isDisabled { get; set; }
        @AuraEnabled public String fieldLabel { get; set; }
        @AuraEnabled public Decimal mobileFormFactorWidth { get; set; }
        @AuraEnabled public Decimal tabFormFactorWidth { get; set; }
        @AuraEnabled public Decimal desktopFormFactorWidth { get; set; }
        @AuraEnabled public String dataType { get; set; }
        @AuraEnabled public Boolean isLightningInputTag { get; set; }
        @AuraEnabled public Boolean isLightningTextArea { get; set; }
        @AuraEnabled public Boolean isLightningComboboxTag { get; set; }
        @AuraEnabled public Boolean isLightningRadioGroupTag { get; set; }
        @AuraEnabled public Boolean isLightningAddressTag { get; set; }
        @AuraEnabled public List<Map<String, Object>> picklistOptions { get; set; } 
    }

    
    @AuraEnabled(cacheable=true)
    public static Map<String, TreeGridResponse> getBluePrintOfTable(String tableApiName) {
    
    try {
        // Get the child table configuration
        Tree_Grid_Configuration__c tableConfigs = getTableConfiguration(tableApiName, 'Data-Table');
        List<Tree_Grid_Configuration__c> fieldConfigs = getFieldConfigurations(tableApiName);

        // Initialize the TreeGridResponse for the child table
        TreeGridResponse tableResponse = initializeResponse(tableConfigs, null);
        buildColumns(fieldConfigs, tableResponse);
        Record recordData = new Record();
        recordData.id = '';
        recordData.isActive = true;
        buildFields(fieldConfigs, null, recordData,tableConfigs );
        tableResponse.records.add(recordData);

        // Add the response to the map using the child API name as the key
        tableConfigBluePrint.put(tableConfigs.Current_Table_Object_Api_Name__c, tableResponse);
        if(tableConfigs.Child_Table_Name__c != NULL){
            getBluePrintOfTable(tableConfigs.Child_Table_Name__c);
        }

    } catch (Exception e) {
        throw new AuraHandledException('Error while generating table blueprint: ' + e.getMessage() + ' at line ' + e.getLineNumber());
    }

    return tableConfigBluePrint;
}


    @AuraEnabled(cacheable=true)
    public static TreeGridResponse getTreeGridData(String tableName, String parentId) {
        try {
            Tree_Grid_Configuration__c tableConfig = getTableConfiguration(tableName, 'Data-Table');
            List<Tree_Grid_Configuration__c> fieldConfigs = getFieldConfigurations(tableName);

            String dynamicQuery = tableConfig.Dynamic_SOQL__c;
            List<SObject> parentRecords = Database.query(dynamicQuery);

            return buildTreeGridResponse(tableConfig, fieldConfigs, parentRecords);
        } catch (Exception e) {
            System.debug('Exception ' + e.getMessage() + ' at line ' + e.getLineNumber());
            throw new AuraHandledException('Error while generating tree grid: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }

    private static TreeGridResponse buildTreeGridResponse(
        Tree_Grid_Configuration__c tableConfig,
        List<Tree_Grid_Configuration__c> fieldConfigs,
        List<SObject> records
    ) {
        TreeGridResponse response = initializeResponse(tableConfig, records);
         if(!response.isRecordsAvailable) return response;

        buildRecords(tableConfig, fieldConfigs, records, response);       
        buildColumns(fieldConfigs, response);
        return response;
    }

    private static void buildColumns(List<Tree_Grid_Configuration__c> fieldConfigs, TreeGridResponse response) {
        for (Tree_Grid_Configuration__c fieldConfig : fieldConfigs) {
            Column column = new Column();
            column.fieldApiName = fieldConfig.Field_API_Name__c;
            column.label = fieldConfig.Field_Label__c;
            column.isSortable = fieldConfig.Is_Sortable__c;
            column.ascDescArrowVariant = fieldConfig.Asc_Desc_Arrow_Variant__c != null ? fieldConfig.Asc_Desc_Arrow_Variant__c : '';
            response.columns.add(column);
        }
    }

    private static void buildRecords(
        Tree_Grid_Configuration__c tableConfig,
        List<Tree_Grid_Configuration__c> fieldConfigs,
        List<SObject> records,
        TreeGridResponse response
    ) {
        
        if(records == null) return;

        for (SObject record : records) {
            Record recordData = new Record();
            recordData.id = (String) record.get('Id');
            recordData.isActive = true;
            buildFields(fieldConfigs, record, recordData, tableConfig);

            String childRelationshipName = tableConfig.Child_Object_Relationship_Name__c != null ? tableConfig.Child_Object_Relationship_Name__c : '';
            if (!String.isEmpty(childRelationshipName)) {
                List<SObject> childRecords = (List<SObject>) record.getSObjects(childRelationshipName);
                childRecords = childRecords != null ? childRecords : new List<SObject>();
                recordData.childRecords = buildTreeGridResponseForChild(tableConfig.Child_Table_Name__c, childRecords);
            }else{
                recordData.childRecords = buildTreeGridResponseForChild(null, null);

            }
            response.records.add(recordData);
        }
    } 
   
    private static void buildFields(List<Tree_Grid_Configuration__c> fieldConfigs, SObject record, Record recordData, Tree_Grid_Configuration__c tableConfig) {
        if(fieldConfigs == null) return;
        Integer columnCount = 1;
        for (Tree_Grid_Configuration__c fieldConfig : fieldConfigs) {
            Field field = new Field();
            field.isFirstColumn = columnCount++ == 1;
            field.fieldApiName = fieldConfig.Field_API_Name__c;
            field.value = record != null ? record.get(fieldConfig.Field_API_Name__c) : '';
            field.isActive = fieldConfig.Is_Active__c;
            field.isRequired = fieldConfig.Is_Required__c;
            field.isDisabled = fieldConfig.Is_Disabled__c;
            field.fieldLabel = fieldConfig.Field_Label__c;
            field.mobileFormFactorWidth = fieldConfig?.Mobile_Form_Factor_Width__c ?? 12;
            field.tabFormFactorWidth = fieldConfig?.Tab_Form_Factor_Width__c ?? 4;
            field.desktopFormFactorWidth = fieldConfig?.Desktop_Form_Factor_Width__c ?? 4;
            field.dataType = fieldConfig.Data_Type__c;
            field.isLightningInputTag = fieldConfig.Is_Lightning_Input_Tag__c ;
            field.isLightningTextArea = fieldConfig.Is_Lightning_Text_Area__c;
            field.isLightningComboboxTag = fieldConfig.Is_Lightning_Combobox__c;
            field.isLightningRadioGroupTag = fieldConfig.Is_Lightning_Radio_Button__c;
            field.isLightningAddressTag = fieldConfig.Is_Lightning_Address__c;
            field.picklistOptions = isPicklist(fieldConfig) ? getPicklistOptions(tableConfig.Current_Table_Object_Api_Name__c, fieldConfig.Field_API_Name__c) : new List<Map<String, Object>>();
            field.linkHref = generateLinkHref(fieldConfig.Link_Href__c, recordData.id);
            recordData.fields.add(field);
        }
    }

    private static String generateLinkHref(String linkHref, String recordId) {
        if (String.isEmpty(linkHref)) return null;
        return linkHref.toLowerCase().contains('recordid') ? '/' + recordId : linkHref;
    }

    private static Boolean isPicklist(Tree_Grid_Configuration__c fieldConfig) {
        return fieldConfig.Data_Type__c == 'combo-box' || fieldConfig.Data_Type__c == 'radio-group';
    }

    private static TreeGridResponse initializeResponse(Tree_Grid_Configuration__c tableConfig, List<SObject> records) {
        TreeGridResponse obj = new TreeGridResponse();       
        obj.isRecordsAvailable = records!= NULL && !records.isEmpty();
        /* if(!obj.isRecordsAvailable) return obj; */
        if(tableConfig == null) return obj; 
        obj.isRecordsEditable = tableConfig?.Is_Records_Editable__c;
        obj.parentLookupFieldApiName = tableConfig?.Parent_Lookup_Field_Api_Name__c;
        obj.objectApiName = tableConfig?.Current_Table_Object_Api_Name__c;
        obj.childObjectApiName = tableConfig?.Child_Table_Object_Api_Name__c;
        obj.isChildRecordCreatable = tableConfig?.Is_Child_Record_Creatable__c;
        obj.currentTableObjectLabel = tableConfig?.Current_Table_Object_Label__c;
        obj.childTableObjectLabel = tableConfig?.Child_Table_Object_Label__c;
        obj.isRecordsDeletable = tableConfig?.Is_Records_Deletable__c;
        System.debug('tableConfig ' + tableConfig);
        system.debug('obj  ' + obj);
        SYstem.debug('obj.isRecordsEditable ' + obj.isRecordsEditable);
        obj.isRecordActionAvailable =  obj != NULL && (obj.isRecordsEditable || obj?.isRecordsDeletable || obj?.isChildRecordCreatable);
        obj.tableHeaderRowCss = tableConfig?.Table_Header_Row_CSS__c;
        obj.tableRecordRowCss = tableConfig?.Table_Record_Row_CSS__c;
        obj.tableBodyCss = tableConfig?.Table_CSS__c;
        obj.mobileFormVerticalSpacing = tableConfig?.Mobile_Form_Table_Vertical_Spacing__c;
        return obj;
    }   

    private static Tree_Grid_Configuration__c getTableConfiguration(String tableName, String type) {
        if (!dataTableConfigMap.containsKey(tableName)) {
            dataTableConfigMap.put(
                tableName,
                [SELECT Name, Type__c,Parent_Lookup_Field_Api_Name__c, Table_Record_Row_CSS__c, 
                Child_Table_Object_Api_Name__c,Child_Table_Object_Label__c, Current_Table_Object_Label__c, 
                Current_Table_Object_Api_Name__c, Asc_Desc_Arrow_Variant__c, Dynamic_SOQL__c, Is_Active__c,
                Is_Child_Record_Creatable__c,Data_Type__c, Mobile_Form_Table_Vertical_Spacing__c, Table_Header_Row_CSS__c, 
                Link_Href__c, Table_CSS__c, Mobile_Form_Factor_Width__c, Tab_Form_Factor_Width__c, 
                Desktop_Form_Factor_Width__c, Child_Object_Relationship_Name__c, Field_Label__c, 
                Field_API_Name__c, Is_Required__c, Is_Records_Editable__c, Is_Records_Deletable__c, 
                Is_Sortable__c, Child_Table_Name__c, Is_Disabled__c, Is_Lightning_Input_Tag__c, Is_Lightning_Text_Area__c, 
                Is_Lightning_Combobox__c, Is_Lightning_Radio_Button__c, Is_Lightning_Address__c 
                FROM Tree_Grid_Configuration__c 
                WHERE Type__c = :type AND Name = :tableName LIMIT 1]
            );
        }
        return dataTableConfigMap.get(tableName);
    }

    private static List<Tree_Grid_Configuration__c> getFieldConfigurations(String tableName) {
        if (!fieldConfigMap.containsKey(tableName)) {
            fieldConfigMap.put(
                tableName,
                [SELECT Name, Type__c, Current_Table_Object_Api_Name__c, Asc_Desc_Arrow_Variant__c, 
                Dynamic_SOQL__c, Is_Active__c, Data_Type__c, Mobile_Form_Table_Vertical_Spacing__c, 
                Table_Header_Row_CSS__c, Link_Href__c, Table_CSS__c, Mobile_Form_Factor_Width__c, 
                Tab_Form_Factor_Width__c, Desktop_Form_Factor_Width__c, Child_Object_Relationship_Name__c, 
                Field_Label__c, Field_API_Name__c, Is_Required__c, Is_Records_Editable__c, Is_Records_Deletable__c, 
                Is_Sortable__c, Child_Table_Name__c, Is_Disabled__c, Is_Lightning_Input_Tag__c,
                Is_Lightning_Text_Area__c, Is_Lightning_Combobox__c, Is_Lightning_Radio_Button__c, Is_Lightning_Address__c
                FROM Tree_Grid_Configuration__c 
                WHERE Type__c = 'Field' AND Is_Active__c = true AND Name = :tableName
                ORDER BY Sequence__c]
            );
        }
        return fieldConfigMap.get(tableName);
    }

    private static List<Map<String, Object>> getPicklistOptions(String objectApiName, String fieldApiName) {
        List<Map<String, Object>> options = new List<Map<String, Object>>();
        try{
            System.debug('objectApiName ' + objectApiName);
            System.debug('fieldApiName ' + fieldApiName);
             Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
            Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get(fieldApiName).getDescribe();
            for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                options.add(new Map<String, Object>{'label' => entry.getLabel(), 'value' => entry.getValue()});
            }
            
        }catch(Exception e){
            throw new AuraHandledException('No picklist found with Object ' + objectApiName + ' and Field ' + fieldApiName + '.');
        }
    
       
        return options;
    }

    private static TreeGridResponse buildTreeGridResponseForChild(String childTableName, List<SObject> childRecords) {
         if(childRecords == null && childTableName  == null) {
            return buildTreeGridResponse(null, null, null);
        }else{
            Tree_Grid_Configuration__c childTableConfig = getTableConfiguration(childTableName, 'Data-Table');
            List<Tree_Grid_Configuration__c> childFieldConfigs = getFieldConfigurations(childTableName);
            return buildTreeGridResponse(childTableConfig, childFieldConfigs, childRecords);
        }        
    }

    @AuraEnabled
    public static String upsertRecords(String objectApiName, Map<String, Object> sObjectRecord, String parentId) {
        try {       
                        
            SObject sObj = tg_SObjectBuilder.buildSObject(objectApiName, sObjectRecord, parentId);
            upsert sObj;
            return sObj.Id;

        } catch (DmlException e) {
            throw new AuraHandledException('Upsert failed: ' + e.getMessage() + ' at line number ' + e.getLineNumber());
        } 
    }

    @AuraEnabled
    public static void deleteRecords(List<Map<String, Object>> sObjectRecords, String objectApiName){
        try {
            List<sObject> sObjectRecordsList = new List<sObject>();
            for(Map<String, Object> sObjectRecord : sObjectRecords) {
                Id recordId = (Id)sObjectRecord.get('Id');
                sObject sObj = Schema.getGlobalDescribe().get(objectApiName).newSObject(recordId);
                sObjectRecordsList.add(sObj);
            }
            delete sObjectRecordsList;
        } catch (Exception e) {
            throw new AuraHandledException('Error when deleting record ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }
}
