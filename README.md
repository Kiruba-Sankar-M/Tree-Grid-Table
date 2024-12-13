### **Tree Grid Configuration Documentation**

UNMANAGED PACKAGE LINK: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tJ4000000gOBF

#### **Overview**  
The Tree Grid Configuration Lightning Web Component (LWC) enables the creation of dynamic and customizable tree grid tables using the configuration provided in the `Tree_Grid_Configuration__c` object. Simply configure the required settings in an Excel sheet, import them into Salesforce, and let the component handle the rest. With minimal effort, this component delivers a robust and flexible tree grid structure tailored to your needs.

---

#### **Why Use This Component?**  
The component addresses limitations in the standard `<lightning-tree-grid>` component by offering:  
- **Enhanced Customization:** Apply custom CSS styles and logic to your table.  
- **Extended Features:** Enable sortable columns and advanced functionalities not supported natively.  
- **Ease of Configuration:** Configure tree grid settings through an easy-to-use blueprint provided in Excel.  

This re-usable LWC simplifies tree grid implementation for scenarios requiring flexibility, customization, and advanced features.

---

#### **When to Use?**  
Use this component for dynamic and efficient tree grid table solutions. It is especially useful when:  
- You require a fully configurable table with child-parent relationships.  
- Your table hierarchy does not exceed five levels, given the SOQL depth limitations.  
- Custom styling, sorting, and logic are necessary for your use case.

---

### **Configuration Instructions**  

#### **Getting Started**  
1. **Download the Excel Template**: Use the [Tree Grid Config README.xlsx](https://github.com/user-attachments/files/18120043/Tree.Grid.Config.README.xlsx)
 as a blueprint for your configurations.  
2. **Explore the Template**: The workbook contains three sheets:
   - **Object Configuration**: Explains the schema of `Tree_Grid_Configuration__c`.  
   - **Data Table Records**: Details for table configurations.  
   - **Field Records**: Details for field configurations.  
3. **Input Your Requirements**: Populate the relevant sheets with the necessary details.

---

#### **Configuring Data Table Records**  
To define data table configurations, fill in the **Data Table Records** sheet as follows:  

1. **`Name`**: Unique name for the table.  
2. **`Type__c`**: Set to `Data-Table`.  
3. **`Current_Table_Object_Api_Name__c`**: The API name of the Salesforce object.  
4. **`Child_Table_Object_Api_Name__c`**: API name of the child object (if applicable).  
5. **`Child_Table_Object_Label__c`**: Label for the child object (e.g., *Opportunity Line Items*).  
6. **`Current_Table_Object_Label__c`**: Label for the current object (e.g., *Opportunity*).  
7. **`Dynamic_SOQL__c`**: Specify the SOQL query to retrieve data. Example:  
   ```sql
   SELECT Id, Name, CloseDate, StageName, Amount, LeadSource, 
   (SELECT Id, Name, ProductCode, Quantity, UnitPrice, TotalPrice FROM OpportunityLineItems) 
   FROM Opportunity WHERE AccountId =: parentId
   ```
   > **Note:** Use `parentId` in the `WHERE` clause to reference the current context record.  
8. **`Child_Object_Relationship_Name__c`**: API name of the child relationship (e.g., `OpportunityLineItems`).  
9. **`Table_Header_Row_CSS__c`**: CSS for table header styling (e.g., `background: grey; font-weight: 700`).  
10. **`Is_Records_Editable__c`**: Boolean to enable record editing.  
11. **`Is_Records_Deletable__c`**: Boolean to enable record deletion.  
12. **`Is_Child_Record_Creatable__c`**: Boolean to enable child record creation.  
13. **`Child_Table_Name__c`**: Name of the `Tree_Grid_Configuration__c` record for the child table.  
14. **`Parent_Lookup_Field_Api_Name__c`**: Lookup field on the current object for its parent (e.g., `AccountId`).  
15. **`Table_Record_Row_CSS__c`**: CSS for row styling (e.g., `background: white`).  
16. **`Mobile_Form_Table_Vertical_Spacing__c`**: Spacing between fields in vertical (mobile) view (e.g., `12ch`).

> **Note:** Ensure `Is_Child_Record_Creatable__c` is set to `false` for the last node in the hierarchy, as no child objects exist beyond this level.

---

#### **Configuring Field Records**  
Define field-level configurations in the **Field Records** sheet.  

1. **`Name`**: Must match the `Name` value in the corresponding data table record.  
2. **`Type__c`**: Set to `Field`.  
3. **`Is_Active__c`**: Boolean to display the column in the table.  
4. **`Data_Type__c`**: Specify the field type (`text`, `date`, `email`, etc.).  
5. **`Mobile_Form_Factor_Width__c`, `Tab_Form_Factor_Width__c`, `Desktop_Form_Factor_Width__c`**: Define column width for each device type (valid values: 1–12).  
6. **`Field_Label__c`**: Label for the field.  
7. **`Field_API_Name__c`**: API name of the field.  
8. **`Is_Required__c`**: Boolean to make the field required.  
9. **`Is_Sortable__c`**: Boolean to enable sorting for the column.  
10. **`Is_Disabled__c`**: Boolean to disable the field during record creation or editing.  
11. **`Link_Href__c`**: URL to link the column (e.g., `/recordId` to navigate to the record page).  
12. **`Asc_Desc_Arrow_Variant__c`**: Specify sorting arrow style (`inverse`, `success`, `error`, etc.).  
13. **`Sequence__c`**: Determines the display order of columns.

---

#### **Post Record Creation**  

1. Drag and drop the **`tg_Parent`** component to the desired location in your Lightning Page.  
2. Specify the **Table Header** and the **Tree Grid Configuration Record Name**.  
3. Your custom tree grid table is ready to use!  
4. Example:  
   ![Tree Grid Example](https://github.com/user-attachments/assets/10a8d32d-2ca2-4396-9871-4e1febe4ca29)  
5. **Key Advantage**: This component allows you to create an unlimited number of tree grid tables. Simply configure records in the `Tree_Grid_Configuration__c` object and provide the corresponding record name when adding the component to your page.


#### **Conclusion**  
With this component, creating a fully functional tree grid is seamless and efficient. By configuring the `Tree_Grid_Configuration__c` object, you gain full control over the structure, style, and behavior of your table. It’s an ideal solution for scenarios requiring dynamic and customized grid structures.
