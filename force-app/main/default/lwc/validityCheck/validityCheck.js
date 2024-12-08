// validationUtils.js
export function setCustomValidity(value, name, isRequired = false, field = {}, formData = {}) {
    let result = { isInputValid: true, validityMessage: '', sldsClass: '' };
    //let field = formData.fields[name];
    let validityMessage = field?.fieldLabel ? `Please enter your ${field.fieldLabel}` : 'This field is required.';

    if (isRequired && !value) {
        return { isInputValid: false, validityMessage, sldsClass: 'slds-has-error' };
    }

    //console.log("inside setcustom validity " + value + ' ' + name);
    switch (name) {
        case 'Phone':
            return validatePhoneInput(value);
        default:
            return result;
    }
}


function validatePhoneInput(value) {
    let result = { isInputValid: true, validityMessage: '', sldsClass: '' };
   
}