import { api, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import upsertRecords from '@salesforce/apex/tg_TreeGridService.upsertRecords';
import { setCustomValidity } from 'c/validityCheck';  // Import the custom validity function

export default class Tg_Modal extends LightningModal {
    @api record = {};
    @api parentId;
    @api saveOrUpdateLabel = '';
    @api headerLabel;
    @api objectApiName = '';
    @api parentLookupFieldApiName;
    isSpinner;


    handleValueChange(event) {

        let { fieldApiName, fieldValue, checked, isCheckbox, isInputValid, validityMessage, sldsClass } = event.detail;
        // Create a deep clone of the record to avoid mutating the original reactive object
        let clonedRecord = JSON.parse(JSON.stringify(this.record));

        // Find the field to update in the cloned record
        let field = clonedRecord.fields.find(field => field.fieldApiName === fieldApiName);

        if (field) {
            if (fieldApiName == 'MailingAddress' || fieldApiName == 'OtherAddress') {
                field.value = {
                    street: fieldValue.street || '',
                    city: fieldValue.city || '',
                    state: fieldValue.state || '',
                    postalCode: fieldValue.postalCode || '',
                    country: fieldValue.country || ''
                };
            } else {
                field.value = isCheckbox ? checked : fieldValue;
            }
            field.isInputValid = isInputValid;
            field.validityMessage = validityMessage;
            field.class = sldsClass;
        }
        // Reassign the cloned object to ensure reactivity
        this.record = clonedRecord;
    }

    handleCancel() {
        this.close();
    }

    validateRecords() {
        //console.log('inside validaterecords');
        let clonedRecord = JSON.parse(JSON.stringify(this.record));
        clonedRecord.fields.forEach(field => {
            //console.log('field ' + JSON.stringify(field, null, 2));

            const { value, fieldApiName, isRequired } = field;
            const { isInputValid, validityMessage, sldsClass } = setCustomValidity(value, fieldApiName, isRequired, field);
            field.isInputValid = isInputValid;
            field.validityMessage = validityMessage;
            field.class = sldsClass;
        });
        this.record = clonedRecord;
    }

    saveRecord() {
        this.validateRecords();
        let isInvalidData = this.record.fields.find(field => !field.isInputValid);
        //console.log('JSON.stringify(isInvalidData) +' + JSON.stringify(isInvalidData));
        if (isInvalidData) {
            return;
        }
        this.isSpinner = true;
        this.disableClose = true;
        const sObjectRecord = this.createSObjectRecord();
        const objectApiName = this.objectApiName;  // Assume this property holds the object name

        // Call Apex method with objectApiName and list of records
        upsertRecords({
            objectApiName: objectApiName,
            sObjectRecord: sObjectRecord,
            parentId: this.parentId
        })
            .then(result => {
                this.disableClose = false;
                this.dispatchToastEventToParent('data', null, '', `Record ${this.saveOrUpdateLabel}d Successfully`, 'success');
                //console.log('Upsert successful:', result);
                this.record = { ...this.record, id: result };
                //console.log('clonedRecord', JSON.stringify(this.record, null, 2));

                this.close(this.record);
            })
            .catch(error => {
                this.disableClose = false;
                this.dispatchToastEventToParent('error', error, `Error upserting record`, '', 'error');
                console.error('Error in upsert:', error);
            })
            .finally(() => {
                this.isSpinner = false;
            });
    }

    createSObjectRecord() {
        let sObjectRecord = {}; // Initialize empty object
        if (this.record.id != '') {
            sObjectRecord.Id = this.record.id;
        }
        // Add fieldApiName-value pairs to the object
        this.record.fields.forEach(field => {
            sObjectRecord[field.fieldApiName] = field.value || null;  // Handle empty values
        });
        if (this.parentLookupFieldApiName && this.record.id != this.parentId) {
            sObjectRecord[this.parentLookupFieldApiName] = this.parentId;
        }
        //console.log('Generated SObject Record: ', JSON.stringify(sObjectRecord));
        return sObjectRecord;
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


}