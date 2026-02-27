import { LightningElement, api, track, wire } from 'lwc';
import getFieldDescriptions from '@salesforce/apex/HandoverService.getFieldDescriptions';

/**
 * @description Handover Notes Section
 * Captures customer goals, risks, relationship info, and operational notes
 */
export default class HandoverSectionNotes extends LightningElement {
    @api customer360Data = {};
    
    // Local state for form values (tracked for reactivity)
    @track _localData = {};
    
    // Field-level help text from Customer_360__c.Other__c (from field settings)
    @track otherHelpText = '';
    
    // Handover Urgency options (default Standard)
    handoverUrgencyOptions = [
        { label: 'Standard', value: 'Standard' },
        { label: 'Urgent', value: 'Urgent' }
    ];

    // Rating options for relationship rating (1-10)
    ratingOptions = [
        { label: '-- Bitte auswählen --', value: '' },
        { label: '1 - Sehr instabil', value: '1' },
        { label: '2', value: '2' },
        { label: '3', value: '3' },
        { label: '4', value: '4' },
        { label: '5 - Neutral', value: '5' },
        { label: '6', value: '6' },
        { label: '7', value: '7' },
        { label: '8', value: '8' },
        { label: '9', value: '9' },
        { label: '10 - Sehr stabil', value: '10' }
    ];
    
    @wire(getFieldDescriptions, {
        objectApiName: 'Customer_360__c',
        fieldApiNames: ['Other__c']
    })
    wiredOtherHelpText({ data }) {
        if (data && data.Other__c) {
            this.otherHelpText = data.Other__c;
        }
    }
    
    connectedCallback() {
        this._localData = {
            handoverUrgency: this.customer360Data.handoverUrgency || 'Standard',
            customerGoals: this.customer360Data.customerGoals || '',
            risks: this.customer360Data.risks || '',
            relationshipRating: this.customer360Data.relationshipRating?.toString() || '',
            relationshipReason: this.customer360Data.relationshipReason || '',
            keyLogistics: this.customer360Data.keyLogistics || '',
            dos: this.customer360Data.dos || '',
            donts: this.customer360Data.donts || '',
            other: this.customer360Data.other || ''
        };
        this.validateSection();
    }
    
    // ============ COMPUTED PROPERTIES ============
    
    get handoverUrgencyValue() {
        return this._localData.handoverUrgency || 'Standard';
    }
    
    get customerGoalsValue() {
        return this._localData.customerGoals || '';
    }
    
    get risksValue() {
        return this._localData.risks || '';
    }
    
    get relationshipRatingValue() {
        return this._localData.relationshipRating || '';
    }
    
    get relationshipReasonValue() {
        return this._localData.relationshipReason || '';
    }
    
    get keyLogisticsValue() {
        return this._localData.keyLogistics || '';
    }
    
    get dosValue() {
        return this._localData.dos || '';
    }
    
    get dontsValue() {
        return this._localData.donts || '';
    }
    
    get otherValue() {
        return this._localData.other || '';
    }
    
    // Character counters for all text fields
    get customerGoalsCharacterCount() {
        return (this._localData.customerGoals || '').length;
    }
    
    get risksCharacterCount() {
        return (this._localData.risks || '').length;
    }
    
    get relationshipReasonCharacterCount() {
        return (this._localData.relationshipReason || '').length;
    }
    
    get keyLogisticsCharacterCount() {
        return (this._localData.keyLogistics || '').length;
    }
    
    get dosCharacterCount() {
        return (this._localData.dos || '').length;
    }
    
    get dontsCharacterCount() {
        return (this._localData.donts || '').length;
    }
    
    get otherCharacterCount() {
        return (this._localData.other || '').length;
    }
    
    // Counter classes for long text fields (32000 chars)
    get customerGoalsCounterClass() {
        return 'slds-text-color_weak slds-text-body_small slds-text-align_right slds-m-top_xx-small';
    }
    
    get risksCounterClass() {
        return 'slds-text-color_weak slds-text-body_small slds-text-align_right slds-m-top_xx-small';
    }
    
    get keyLogisticsCounterClass() {
        return 'slds-text-color_weak slds-text-body_small slds-text-align_right slds-m-top_xx-small';
    }
    
    get otherCounterClass() {
        const count = this.otherCharacterCount;
        if (count > 32000) {
            return 'slds-text-color_error slds-text-body_small slds-text-align_right slds-m-top_xx-small';
        }
        return 'slds-text-color_weak slds-text-body_small slds-text-align_right slds-m-top_xx-small';
    }
    
    // Counter classes for fields with strict limits (255 chars)
    get relationshipReasonCounterClass() {
        const count = this.relationshipReasonCharacterCount;
        if (count > 255) {
            return 'slds-text-color_error slds-text-body_small slds-text-align_right slds-m-top_xx-small';
        } else if (count > 230) {
            return 'slds-text-color_weak slds-text-body_small slds-text-align_right slds-m-top_xx-small';
        }
        return 'slds-text-color_weak slds-text-body_small slds-text-align_right slds-m-top_xx-small';
    }
    
    get dosCounterClass() {
        const count = this.dosCharacterCount;
        if (count > 255) {
            return 'slds-text-color_error slds-text-body_small slds-text-align_right slds-m-top_xx-small';
        } else if (count > 230) {
            return 'slds-text-color_weak slds-text-body_small slds-text-align_right slds-m-top_xx-small';
        }
        return 'slds-text-color_weak slds-text-body_small slds-text-align_right slds-m-top_xx-small';
    }
    
    get dontsCounterClass() {
        const count = this.dontsCharacterCount;
        if (count > 255) {
            return 'slds-text-color_error slds-text-body_small slds-text-align_right slds-m-top_xx-small';
        } else if (count > 230) {
            return 'slds-text-color_weak slds-text-body_small slds-text-align_right slds-m-top_xx-small';
        }
        return 'slds-text-color_weak slds-text-body_small slds-text-align_right slds-m-top_xx-small';
    }
    
    // ============ EVENT HANDLERS ============
    
    handleCustomerGoalsChange(event) {
        this._localData.customerGoals = event.target.value;
        this.dispatchDataChange('customerGoals', event.target.value);
        this.validateSection();
    }
    
    handleRisksChange(event) {
        this._localData.risks = event.target.value;
        this.dispatchDataChange('risks', event.target.value);
        this.validateSection();
    }
    
    handleRelationshipRatingChange(event) {
        this._localData.relationshipRating = event.detail.value;
        this.dispatchDataChange('relationshipRating', event.detail.value);
        this.validateSection();
    }
    
    handleRelationshipReasonChange(event) {
        this._localData.relationshipReason = event.target.value;
        this.dispatchDataChange('relationshipReason', event.target.value);
        this.validateSection();
    }
    
    handleKeyLogisticsChange(event) {
        this._localData.keyLogistics = event.target.value;
        this.dispatchDataChange('keyLogistics', event.target.value);
        this.validateSection();
    }
    
    handleDosChange(event) {
        this._localData.dos = event.target.value;
        this.dispatchDataChange('dos', event.target.value);
        this.validateSection();
    }
    
    handleDontsChange(event) {
        this._localData.donts = event.target.value;
        this.dispatchDataChange('donts', event.target.value);
        this.validateSection();
    }
    
    handleOtherChange(event) {
        this._localData.other = event.target.value;
        this.dispatchDataChange('other', event.target.value);
        this.validateSection();
    }
    
    handleHandoverUrgencyChange(event) {
        this._localData.handoverUrgency = event.detail.value;
        this.dispatchDataChange('handoverUrgency', event.detail.value);
        this.validateSection();
    }
    
    // ============ PUBLIC METHODS ============
    
    @api
    triggerSave() {
        // Validate and highlight ALL invalid fields
        const isValid = this.validateAndHighlightAllFields();
        
        if (isValid) {
            // Convert rating back to number; handoverUrgency stays as string
            const dataToSave = { 
                ...this._localData,
                handoverUrgency: this._localData.handoverUrgency || 'Standard',
                relationshipRating: this._localData.relationshipRating 
                    ? parseInt(this._localData.relationshipRating, 10) 
                    : null
            };
            
            this.dispatchEvent(new CustomEvent('sectionsave', {
                detail: {
                    section: 'notes',
                    data: dataToSave
                }
            }));
        }
    }
    
    // ============ PRIVATE METHODS ============
    
    /**
     * Validates all fields and highlights ALL invalid ones
     * @returns {boolean} true if all fields are valid
     */
    validateAndHighlightAllFields() {
        let allValid = true;
        
        // Validate all textareas
        const textareas = this.template.querySelectorAll('lightning-textarea');
        textareas.forEach(textarea => {
            const value = textarea.value || '';
            if (textarea.name === 'dos' || textarea.name === 'donts') {
                if (value.length > 255) {
                    textarea.setCustomValidity('Maximal 255 Zeichen erlaubt. Aktuell: ' + value.length + ' Zeichen.');
                    allValid = false;
                } else {
                    textarea.setCustomValidity('');
                }
            } else if (textarea.name === 'other') {
                if (value.length > 32000) {
                    textarea.setCustomValidity('Maximal 32.000 Zeichen erlaubt. Aktuell: ' + value.length + ' Zeichen.');
                    allValid = false;
                } else {
                    textarea.setCustomValidity('');
                }
            }
            const fieldValid = textarea.reportValidity();
            if (!fieldValid) {
                allValid = false;
            }
        });
        
        // Validate all inputs
        const inputs = this.template.querySelectorAll('lightning-input');
        inputs.forEach(input => {
            const fieldValid = input.reportValidity();
            if (!fieldValid) {
                allValid = false;
            }
        });
        
        // Validate all comboboxes
        const comboboxes = this.template.querySelectorAll('lightning-combobox');
        comboboxes.forEach(combobox => {
            const fieldValid = combobox.reportValidity();
            if (!fieldValid) {
                allValid = false;
            }
        });
        
        return allValid;
    }
    
    validateSection() {
        // Required fields + character limit check for dos/donts; other is optional with 32k limit
        const dosLength = (this._localData.dos || '').length;
        const dontsLength = (this._localData.donts || '').length;
        const otherLength = (this._localData.other || '').length;
        
        const isValid = 
            this._localData.customerGoals !== '' &&
            this._localData.risks !== '' &&
            this._localData.relationshipRating !== '' &&
            this._localData.relationshipReason !== '' &&
            this._localData.keyLogistics !== '' &&
            this._localData.dos !== '' &&
            this._localData.donts !== '' &&
            dosLength <= 255 &&
            dontsLength <= 255 &&
            otherLength <= 32000;
        
        this.dispatchEvent(new CustomEvent('sectionvalidity', {
            detail: { valid: isValid }
        }));
        
        return isValid;
    }
    
    dispatchDataChange(field, value) {
        this.dispatchEvent(new CustomEvent('datachange', {
            detail: { field, value }
        }));
    }
}