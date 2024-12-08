import { LightningElement, api } from 'lwc';
import { setCustomValidity } from 'c/validityCheck';
import LightningConfirm from 'lightning/confirm';

export default class Tg_Field extends LightningElement {

    @api field = {};
    modalUrl = '';
    showModal = false;
    isSpinner;
    @api parentId;


    changeHandler(event) {
        let { name, value, checked, type } = event.target;
        const isCheckbox = type === 'checkbox' || type === 'checkbox-button' || type === 'toggle';
        const { isInputValid, validityMessage, sldsClass } = setCustomValidity(isCheckbox ? checked : value, name, this.field.isRequired, this.field);
        if (name == 'MailingAddress' || name == 'OtherAddress') {

            value = {
                street: event.target.street || '',
                city: event.target.city || '',
                state: event.target.province || '',
                postalCode: event.target.postalCode || '',
                country: event.target.country || ''
            };
            //console.log('Valuee ' + JSON.stringify(value));

        }
        this.dispatchEvent(
            new CustomEvent('updateformdata', {
                detail: {
                    sectionName: this.field.sectionName,
                    pageName: this.field.pageName,
                    fieldApiName: name,
                    fieldValue: isCheckbox ? checked : value,
                    type: 'field',
                    isInputValid,
                    sldsClass,
                    validityMessage
                },
                bubbles: true,
                composed: true
            })
        );
    }

    closeModal() {
        this.showModal = false;
    }

    async handleConfirmClick(documentName) {
        return await LightningConfirm.open({
            message: `Are you sure you want to delete the uploaded ${documentName}`,
            variant: 'default',
            label: 'Confirmation for deleting uploaded file',
        });
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