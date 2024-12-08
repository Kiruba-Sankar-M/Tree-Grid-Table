import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import tg_Modal from 'c/tg_Modal';
import getTreeGridData from '@salesforce/apex/tg_TreeGridService.getTreeGridData';
import getBluePrintOfTable from '@salesforce/apex/tg_TreeGridService.getBluePrintOfTable';

export default class Tg_Parent extends LightningElement {
    @track tableData = {};
    @api tableHeader = ''
    selectedRecordId = '';
    @api recordId = '';
    isSpinner;
    @api tableName = '';
    @track updatedObject = {}
    @track tableBluePrint = {};
    isCompleteRecursion = false;
    get addParentRecordLabel() {
        return `Add ${this.tableData?.currentTableObjectLabel} Record`;
    }

    handleAddParent() {
        this.openModal('Save', `Create New ${this.tableData.currentTableObjectLabel} Record`)
    }

    async openModal(saveOrUpdateLabel, headerLabel ) {
        let result = await tg_Modal.open({
            size: 'large',
            record: this.getOrCreateFields(),
            headerLabel,
            parentId: this.recordId,
            objectApiName : this.tableData.objectApiName,
            parentLookupFieldApiName : this.tableData.parentLookupFieldApiName,
            saveOrUpdateLabel,
            onshowtoast: (e) => {
                e.stopPropagation();
                this.handleSuccess('',`${this.tableData.currentTableObjectLabel} Record Created Successfully`);
            }
        });

        if (result) {
            this.updateRecordsArray(result);
        }
    }

    updateRecordsArray(incomingRecord) {
        const { id, fields } = incomingRecord;
        
        let clonedTableData = structuredClone(this.tableData);
        if (clonedTableData.records.length == 0) {
            clonedTableData = { ...this.tableBluePrint[clonedTableData.objectApiName] }
            clonedTableData.records = [];
        }
       
        let record = {};
                          
        record.id = id;
        let field = fields.find(field => field.linkHref != '');
        if (field) {
            field.linkHref = `/${id}`
        }
        record.fields = fields;
        record.isExpanded = false;
        record.childRecords = {};
        record.childRecords.isRecordsAvailable = false;
        clonedTableData.records.push(record);
        clonedTableData.isRecordsAvailable = clonedTableData.records.length > 0;
        
        this.tableData = clonedTableData;
    }
    
    getOrCreateFields() {
         if (this.tableBluePrint.hasOwnProperty(this.tableData.objectApiName)) {
                return {
                    id: '',
                    objectApiName: this.tableData.objectApiName,
                    fields : this.tableBluePrint[this.tableData.objectApiName].records[0].fields.map(field => ({
                        ...field,
                        value: ''
                    }))
                }
        }
    }

    connectedCallback() {
        this.isSpinner = true;
        getBluePrintOfTable({ tableApiName: this.tableName })
            .then(result => {
                this.tableBluePrint = result;
                console.log('tableBluePrint: ' + JSON.stringify(this.tableBluePrint));
            })
            .catch(error => {
                this.handleError( error, `Error fetching table blueprint`);
            }).finally(() => {
                this.isSpinner = false;
            });
    

        if (this.tableData?.records?.length) {
            return;
        }

        getTreeGridData({ tableName: this.tableName, parentId: this.recordId })
            .then((result) => {
                this.tableData = result;
                console.log('tableData: ' + JSON.stringify(this.tableData));
            })
            .catch((error) => {
                this.handleError(error, "Error fetching tree grid data");
            })
            .finally(() => {
                this.isSpinner = false;
            });
        
    }

   dataUpdation(data) {
    if (!data || !data.records) {
        return;
    }

    // Iterate through each record
    data.records.forEach(record => {
        if (this.updateRecord(record, data)) {
            return; // Stop further recursion if record is found and updated
        }

        // If child records exist, recursively update them
        if (record.childRecords && record.childRecords.records) {
            this.dataUpdation(record.childRecords);
        }
    });
    return data;
}

    keepTableDataInSync(event) {
        event.stopPropagation();
        let { recordId, updatedObject } = event.detail;
        this.selectedRecordId = recordId;
        this.updatedObject = updatedObject;

        // Clone data to avoid mutation issues
        this.tableData = this.dataUpdation(JSON.parse(JSON.stringify(this.tableData)));
    }

updateRecord(record, data) {
    if (record.id === this.selectedRecordId) {
        // Update the record directly
        Object.assign(data, this.updatedObject);
        data.isRecordsAvailable = this.updatedObject?.records?.length >= 1;
        data.isExpanded = data.isRecordsAvailable;
        return true; // Indicate that the record has been updated
    }
    return false; // Continue searching
}

    handleSuccess(title, message, variant = "success") {
        this.showToast(title, message, variant);
    }


    handleError(error, title) {
        let message = "Unknown error";
        if (error && Array.isArray(error.body)) {
            message = error.body.map((e) => e.message).join(", ");
        } else if (error && typeof error.body.message === "string") {
            message = error.body.message;
        }
        this.showToast(title, message, "error");
    }


     showToast(title, message, variant = 'info', mode = 'dismissable') {
        const toastEvent = new ShowToastEvent({
            title,
            message,
            variant, // Variant can be 'info', 'success', 'warning', or 'error'
            mode // Mode can be 'dismissable', 'sticky', or 'pester'
        });
        this.dispatchEvent(toastEvent);
     }
    handleShowToastFromChildEvent(event) {
        if (event.detail.dataOrError === "data") {
            this.handleSuccess(event.detail?.title, event.detail?.message, event.detail?.variant);
        } else if (event.detail.dataOrError === "error") {
            this.handleError(event.detail?.property, event.detail?.title);
        }
    }
    
}