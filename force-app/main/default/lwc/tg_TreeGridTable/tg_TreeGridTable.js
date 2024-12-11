import { LightningElement, api } from 'lwc';
import tg_Modal from 'c/tg_Modal';
import LightningConfirm from "lightning/confirm";
import deleteRecords from '@salesforce/apex/tg_TreeGridService.deleteRecords';
export default class Tg_TreeGridTable extends LightningElement {

    @api tableData = {};
    @api parentRecordId;
    @api tableBluePrint = {};
    selectedRecordId;
    isSpinner;
    isStylingAlreadyFixed = false;   

    
    
    renderedCallback() {
        if (!this.tableData?.mobileFormVerticalSpacing?.endsWith('ch') || this.isStylingAlreadyFixed) {
            return;
        }
        this.isStylingAlreadyFixed = true;
        let tds = this.template.querySelectorAll('.table-data');
        if (tds.length > 0) {
            tds.forEach(td => {
                td.style.setProperty('--table-vertical-spacing', this.tableData.mobileFormVerticalSpacing);
            });
        } else {
            console.warn('No elements with class .table-data found.');
        }
    }

    handleSorting(event) {
        let isSortable = event.currentTarget.dataset.isSortable;
        if (isSortable == 'true') {
            let sortBy = event.currentTarget.dataset.fieldName;
            let sortDirection = event.currentTarget.dataset.sortDirection || 'asc';
            this.sortData(sortBy, sortDirection);
        }
        
    }

     sortData(fieldApiName, direction) {
        // Deep copy the records to avoid mutating the original data
         let parsedRecords = JSON.parse(JSON.stringify(this.tableData.records));
         let parsedColumns = JSON.parse(JSON.stringify(this.tableData.columns));
         let column = parsedColumns.find(column => column.fieldApiName == fieldApiName);
         parsedColumns.forEach((column, index) => {
             column.isAscending = false;
             column.isDescending = false;
         }
         );
        if (column) {
            column.sortDirection = direction === 'asc' ? 'desc' : 'asc'; 
            column.isAscending = direction === 'asc';
            column.isDescending = direction === 'desc';
        }

         
        // Helper function to extract the field value for sorting
        const keyValue = (record) => {
            const field = record.fields.find((f) => f.fieldApiName === fieldApiName);
            return field ? field.value : ''; // Return field value or an empty string if not found
        };

        // Determine sort order
        const isReverse = direction === 'asc' ? 1 : -1;

        // Sort the data
        parsedRecords.sort((a, b) => {
            const x = keyValue(a) ? keyValue(a).toString().toLowerCase() : ''; // Convert to string and handle case insensitivity
            const y = keyValue(b) ? keyValue(b).toString().toLowerCase() : '';

            return isReverse * ((x > y) - (y > x)); // Sort logic
        });

        // Update the tableData records with sorted data
        this.tableData = {
            ...this.tableData,
            records: parsedRecords,
            columns : parsedColumns
        };
    }   
    handleEditRecord(event) {
        let recordId = event.target.dataset.id;
        this.openModal(recordId, 'Update', `Update ${this.tableData.currentTableObjectLabel}`);
    }

    handleAddRow(event) {
        let recordId = event.target.dataset.id;
        this.selectedRecordId = recordId;
        this.openModal(recordId, 'Save', `Create ${this.tableData.childTableObjectLabel}`);
    }


    async openModal(recordId, saveOrUpdateLabel, headerLabel ) {
        let result = await tg_Modal.open({
            size: 'large',
            record: this.getOrCreateFields(recordId, saveOrUpdateLabel == 'Update'),
            headerLabel,
            parentId: recordId,
            objectApiName : saveOrUpdateLabel == 'Update' ? this.tableData.objectApiName : this.tableData.childObjectApiName,
            parentLookupFieldApiName : this.tableData.records[0].childRecords.parentLookupFieldApiName,
            saveOrUpdateLabel,
            onshowtoast: (e) => {
                e.stopPropagation();
                let { dataOrError, property, title, message, variant } = e.detail;
                this.dispatchToastEventToParent(dataOrError, property, title, message, variant);
            }
        });

        if (result) {
            this.updateRecordsArray(result);
        }
    }

    handleExpand(event) {
        let recordId = event.target.dataset.recordId;
        if (this.tableData?.records && this.tableData.records.length) {
            let clonedData = JSON.parse(JSON.stringify(this.tableData))
            let record = clonedData.records.find(record => record.id == recordId);
            if (record) {
                record.isExpanded = !record.isExpanded;
            }
            this.tableData = clonedData;
        }
        this.dispatchUpdateToParent(recordId, this.tableData);
    }

    getOrCreateFields(recordId, isCurrentTable) {
        if (isCurrentTable) {
            const record = this.tableData.records.find(record => record.id == recordId);
            if (record) {
                return { ...record, objectApiName: this.tableData.objectApiName };
            }
        } else {
            if (!this.tableBluePrint.hasOwnProperty(this.tableData.childObjectApiName)){
                this.dispatchToastEventToParent('error', error, `No child object api name specified on ${this.tableData.currentTableObjectLabel} datatable`, '', 'error');
                return;
            }
            if (this.tableBluePrint.hasOwnProperty(this.tableData.childObjectApiName)) {
                return {
                    id: '',
                    objectApiName: this.tableData.childObjectApiName,
                    fields : this.tableBluePrint[this.tableData.childObjectApiName].records[0].fields.map(field => ({
                        ...field,
                        value: ''
                    }))
                }
            }
        }
    }

    createSObjectRecord(record) {
        let sObjectRecord = {}; // Initialize empty object
        if (record.id != '') {
            sObjectRecord.Id = record.id;
        }
        record.fields.forEach(field => {
            sObjectRecord[field.fieldApiName] = field.value || null;  // Handle empty values
        });

        return sObjectRecord;
    }
    async handleDeleteRecord(event) {
        let recordId = event.target.dataset.id;
        const result = await LightningConfirm.open({
            message: "Are you sure you want to delete this?",
            variant: "default", // headerless
            label: "Delete a record"
        });

        if (result) {
            this.isSpinner = true;
            let record = this.getOrCreateFields(recordId, true);
            let sObjectMap = this.createSObjectRecord(record);
           
            deleteRecords({ sObjectRecords: [sObjectMap], objectApiName: this.tableData.objectApiName })
                .then(() => {
                    let clonedTableData = JSON.parse(JSON.stringify(this.tableData));
                    clonedTableData.records = clonedTableData.records.filter(record => record.id != recordId);
                    clonedTableData.isRecordsAvailable = clonedTableData.records.length >= 1;
                    //clonedTableData.isExpanded = clonedTableData.isRecordsAvailable;
                    clonedTableData.isExpanded = true;
                    this.tableData = clonedTableData;
                    this.dispatchToastEventToParent('data', null, '', `Record Deleted Successfully`, 'success');
                    this.dispatchUpdateToParent(recordId, clonedTableData);
                }).catch(error => {
                    this.dispatchToastEventToParent('error', error, `Error Deleting record`, '', 'error');
                }).finally(() => {
                    this.isSpinner = false;
                });
        }
    }
    
    updateRecordsArray(incomingRecord) {
        const { id, fields } = incomingRecord;
        
        let clonedTableData = JSON.parse(JSON.stringify(this.tableData));
        const existingIndex = clonedTableData.records.findIndex(record => record.id === id);
        if (existingIndex != -1) {
            clonedTableData.records[existingIndex].fields = fields;
            this.dispatchUpdateToParent(id, clonedTableData);
        } else {
            let record = clonedTableData.records.find(record => record.id == this.selectedRecordId)
            if (record) {
                let childRecord = {};        
                childRecord.id = id;
                let clonedFields = [...fields];
                console.log('field  ' + JSON.stringify(clonedFields));
                let fieldIndex = clonedFields.findIndex(field => field.linkHref && (field?.linkHref.includes('recordId') || field?.linkHref.includes('recordid') ));
                console.log('index ' + fieldIndex);
                if (fieldIndex != -1) {
                    console.log('fieldIndex ' + fieldIndex);
                    clonedFields[fieldIndex].linkHref = `/${id}`
                }
                childRecord.fields = clonedFields;
                childRecord.isExpanded = true;
                childRecord.childRecords = {};
                if (this.tableBluePrint.hasOwnProperty(this.tableData.childObjectApiName) && !record.childRecords?.records?.length) {
                    record.childRecords = { ...this.tableBluePrint[this.tableData.childObjectApiName] };
                    record.childRecords.records = [];
                }    
                childRecord.childRecords.isRecordsAvailable = false;   

                record.childRecords.records.push(childRecord);
                record.childRecords.isRecordsAvailable = record.childRecords.records.length >= 1;
                //record.childRecords.isExpanded = record.childRecords.isRecordsAvailable;
                record.childRecords.isExpanded = record.childRecords.isRecordsAvailable;
                
                
                this.dispatchUpdateToParent(this.selectedRecordId, clonedTableData);            
            }
            
             
        }
    
        this.tableData = clonedTableData;
    }

    dispatchToastEventToParent(dataOrError, property, title, message, variant) {
        //property is data / error 

        //dataOrError is a string to notify parent whether this event is published for successful / unsuccessful dml's.
        //expected values for dataOrError are "data", "error"; "data" will be passed in .then() block, "error" will be passed in .catch() block.

        this.dispatchEvent(new CustomEvent('showtoast', {
            detail: { dataOrError, property, title, message, variant },
            bubbles: true,
            composed: true
        }));
    }

    dispatchUpdateToParent(recordId, updatedObject) {

        this.dispatchEvent(
            new CustomEvent('updatetabledata', {
                detail: {
                    recordId: recordId,
                    updatedObject: updatedObject,
                },
                bubbles: true,
                composed: true
            })
        );
    } 
}