import { LightningElement, api, track, wire } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import OPEN_JOBS_FIELD from '@salesforce/schema/Account.plOpenJobs__c';
import getContactDetails from '@salesforce/apex/HandoverService.getContactDetails';

/**
 * @description Consolidated Pre-check Section
 * Displays Account data, allows editing, and includes contact management
 */
export default class HandoverSectionPreChecks extends LightningElement {
    @api customer360Data = {};
    @api autoPulledContext = {};
    @api fieldDescriptions = {};
    
    // Local state for form values
    @track _localData = {};
    @track _isRefreshingStrategic = false;
    @track _isRefreshingOperational = false;
    
    // Picklist options
    @track openJobsOptions = [];
    
    // Wire to get Account object info (needed for record type ID)
    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    accountInfo;
    
    // Wire to get Open Jobs picklist values
    @wire(getPicklistValues, { 
        recordTypeId: '$defaultRecordTypeId', 
        fieldApiName: OPEN_JOBS_FIELD 
    })
    wiredOpenJobsPicklist({ error, data }) {
        if (data) {
            this.openJobsOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            // Picklist loading failed; field will show without options
        }
    }
    
    // Get default record type ID for Account
    get defaultRecordTypeId() {
        return this.accountInfo?.data?.defaultRecordTypeId;
    }
    
    connectedCallback() {
        // Initialize local data from customer360Data
        this._localData = {
            // Parent Account
            parentAccountId: this.customer360Data.parentAccountId || this.autoPulledContext.parentAccountId || '',
            // Editable account fields
            employees: this.customer360Data.employees,
            openJobs: this.customer360Data.openJobs,
            estimatedWalletSize: this.customer360Data.estimatedWalletSize,
            // Strategic contact
            strategicContactId: this.customer360Data.strategicContactId || '',
            strategicContactFirstName: this.customer360Data.strategicContactFirstName || '',
            strategicContactLastName: this.customer360Data.strategicContactLastName || '',
            strategicContactEmail: this.customer360Data.strategicContactEmail || '',
            strategicContactPhone: this.customer360Data.strategicContactPhone || '',
            strategicContactTitle: this.customer360Data.strategicContactTitle || '',
            // Operational contact
            operationalContactId: this.customer360Data.operationalContactId || '',
            operationalContactFirstName: this.customer360Data.operationalContactFirstName || '',
            operationalContactLastName: this.customer360Data.operationalContactLastName || '',
            operationalContactEmail: this.customer360Data.operationalContactEmail || '',
            operationalContactPhone: this.customer360Data.operationalContactPhone || '',
            operationalContactTitle: this.customer360Data.operationalContactTitle || ''
        };
        this.validateSection();
    }
    
    // ============ COMPUTED PROPERTIES ============
    
    // Ultimate Parent Account (read-only formula field value)
    get ultimateParentDisplay() {
        return this.autoPulledContext.ultimateParentAccount || '-';
    }
    
    get ultimateParentHelpText() {
        return this.fieldDescriptions?.['Ultimate_Parent_Account__c'] || 
               'Das Ultimate Parent Account basierend auf der Hierarchie.';
    }
    
    get parentAccountHelpText() {
        return this.fieldDescriptions?.['ParentId'] || 
               'Das übergeordnete Account. Bei Bedarf ändern.';
    }
    
    get parentAccountIdValue() {
        return this._localData.parentAccountId || null;
    }
    
    get gtmMotionDisplay() {
        return this.autoPulledContext.gtmMotion || '-';
    }
    
    // Current values for form fields
    get employeesValue() {
        return this._localData.employees;
    }
    
    get openJobsValue() {
        return this._localData.openJobs;
    }
    
    get ewsValue() {
        return this._localData.estimatedWalletSize;
    }
    
    get ewsDisplayValue() {
        const value = this._localData.estimatedWalletSize || this.autoPulledContext.estimatedWalletSize;
        if (value != null && value !== '') {
            return new Intl.NumberFormat('de-DE', { 
                style: 'currency', 
                currency: 'EUR' 
            }).format(value);
        }
        return '-';
    }
    
    // Strategic Contact computed properties
    get strategicContactIdValue() {
        return this._localData.strategicContactId || null;
    }
    
    get strategicContactName() {
        const first = this._localData.strategicContactFirstName || '';
        const last = this._localData.strategicContactLastName || '';
        return `${first} ${last}`.trim() || 'Kein Kontakt ausgewählt';
    }
    
    get strategicContactFirstNameValue() {
        return this._localData.strategicContactFirstName || '';
    }
    
    get strategicContactLastNameValue() {
        return this._localData.strategicContactLastName || '';
    }
    
    get strategicContactEmailValue() {
        return this._localData.strategicContactEmail || '';
    }
    
    get strategicContactPhoneValue() {
        return this._localData.strategicContactPhone || '';
    }
    
    get strategicContactTitleValue() {
        return this._localData.strategicContactTitle || '';
    }
    
    get isStrategicRefreshDisabled() {
        return !this._localData.strategicContactId || this._isRefreshingStrategic;
    }
    
    // Operational Contact computed properties
    get operationalContactIdValue() {
        return this._localData.operationalContactId || null;
    }
    
    get operationalContactName() {
        const first = this._localData.operationalContactFirstName || '';
        const last = this._localData.operationalContactLastName || '';
        return `${first} ${last}`.trim() || 'Kein Kontakt ausgewählt';
    }
    
    get operationalContactFirstNameValue() {
        return this._localData.operationalContactFirstName || '';
    }
    
    get operationalContactLastNameValue() {
        return this._localData.operationalContactLastName || '';
    }
    
    get operationalContactEmailValue() {
        return this._localData.operationalContactEmail || '';
    }
    
    get operationalContactPhoneValue() {
        return this._localData.operationalContactPhone || '';
    }
    
    get operationalContactTitleValue() {
        return this._localData.operationalContactTitle || '';
    }
    
    get isOperationalRefreshDisabled() {
        return !this._localData.operationalContactId || this._isRefreshingOperational;
    }
    
    // ============ EVENT HANDLERS ============
    
    // Parent Account change
    handleParentAccountChange(event) {
        const selectedId = event.detail.recordId;
        this._localData.parentAccountId = selectedId || '';
        this.dispatchDataChange('parentAccountId', selectedId || '');
    }
    
    // Account field changes
    handleEmployeesChange(event) {
        this._localData.employees = event.target.value ? parseInt(event.target.value, 10) : null;
        this.dispatchDataChange('employees', this._localData.employees);
    }
    
    handleOpenJobsChange(event) {
        this._localData.openJobs = event.detail.value || '';
        this.dispatchDataChange('openJobs', this._localData.openJobs);
    }
    
    handleEwsChange(event) {
        this._localData.estimatedWalletSize = event.target.value ? parseFloat(event.target.value) : null;
        this.dispatchDataChange('estimatedWalletSize', this._localData.estimatedWalletSize);
    }
    
    // Strategic Contact handlers
    handleStrategicContactSelect(event) {
        const selectedId = event.detail.recordId;
        this._localData.strategicContactId = selectedId || '';
        this.dispatchDataChange('strategicContactId', selectedId || '');
    }
    
    async handleStrategicContactRefresh() {
        if (!this._localData.strategicContactId) return;
        
        this._isRefreshingStrategic = true;
        try {
            const contactInfo = await getContactDetails({ 
                contactId: this._localData.strategicContactId 
            });
            
            if (contactInfo) {
                this._localData.strategicContactFirstName = contactInfo.firstName || '';
                this._localData.strategicContactLastName = contactInfo.lastName || '';
                this._localData.strategicContactEmail = contactInfo.email || '';
                this._localData.strategicContactPhone = contactInfo.phone || '';
                this._localData.strategicContactTitle = contactInfo.title || '';
                
                // Dispatch all changes
                this.dispatchDataChange('strategicContactFirstName', this._localData.strategicContactFirstName);
                this.dispatchDataChange('strategicContactLastName', this._localData.strategicContactLastName);
                this.dispatchDataChange('strategicContactEmail', this._localData.strategicContactEmail);
                this.dispatchDataChange('strategicContactPhone', this._localData.strategicContactPhone);
                this.dispatchDataChange('strategicContactTitle', this._localData.strategicContactTitle);
            }
        } catch (error) {
            // Silently handled; toast already shown by parent container
        } finally {
            this._isRefreshingStrategic = false;
        }
    }
    
    handleStrategicFirstNameChange(event) {
        this._localData.strategicContactFirstName = event.target.value;
        this.dispatchDataChange('strategicContactFirstName', event.target.value);
    }
    
    handleStrategicLastNameChange(event) {
        this._localData.strategicContactLastName = event.target.value;
        this.dispatchDataChange('strategicContactLastName', event.target.value);
    }
    
    handleStrategicEmailChange(event) {
        this._localData.strategicContactEmail = event.target.value;
        this.dispatchDataChange('strategicContactEmail', event.target.value);
    }
    
    handleStrategicPhoneChange(event) {
        this._localData.strategicContactPhone = event.target.value;
        this.dispatchDataChange('strategicContactPhone', event.target.value);
    }
    
    handleStrategicTitleChange(event) {
        this._localData.strategicContactTitle = event.target.value;
        this.dispatchDataChange('strategicContactTitle', event.target.value);
    }
    
    // Operational Contact handlers
    handleOperationalContactSelect(event) {
        const selectedId = event.detail.recordId;
        this._localData.operationalContactId = selectedId || '';
        this.dispatchDataChange('operationalContactId', selectedId || '');
    }
    
    async handleOperationalContactRefresh() {
        if (!this._localData.operationalContactId) return;
        
        this._isRefreshingOperational = true;
        try {
            const contactInfo = await getContactDetails({ 
                contactId: this._localData.operationalContactId 
            });
            
            if (contactInfo) {
                this._localData.operationalContactFirstName = contactInfo.firstName || '';
                this._localData.operationalContactLastName = contactInfo.lastName || '';
                this._localData.operationalContactEmail = contactInfo.email || '';
                this._localData.operationalContactPhone = contactInfo.phone || '';
                this._localData.operationalContactTitle = contactInfo.title || '';
                
                // Dispatch all changes
                this.dispatchDataChange('operationalContactFirstName', this._localData.operationalContactFirstName);
                this.dispatchDataChange('operationalContactLastName', this._localData.operationalContactLastName);
                this.dispatchDataChange('operationalContactEmail', this._localData.operationalContactEmail);
                this.dispatchDataChange('operationalContactPhone', this._localData.operationalContactPhone);
                this.dispatchDataChange('operationalContactTitle', this._localData.operationalContactTitle);
            }
        } catch (error) {
            // Silently handled; toast already shown by parent container
        } finally {
            this._isRefreshingOperational = false;
        }
    }
    
    handleOperationalFirstNameChange(event) {
        this._localData.operationalContactFirstName = event.target.value;
        this.dispatchDataChange('operationalContactFirstName', event.target.value);
    }
    
    handleOperationalLastNameChange(event) {
        this._localData.operationalContactLastName = event.target.value;
        this.dispatchDataChange('operationalContactLastName', event.target.value);
    }
    
    handleOperationalEmailChange(event) {
        this._localData.operationalContactEmail = event.target.value;
        this.dispatchDataChange('operationalContactEmail', event.target.value);
    }
    
    handleOperationalPhoneChange(event) {
        this._localData.operationalContactPhone = event.target.value;
        this.dispatchDataChange('operationalContactPhone', event.target.value);
    }
    
    handleOperationalTitleChange(event) {
        this._localData.operationalContactTitle = event.target.value;
        this.dispatchDataChange('operationalContactTitle', event.target.value);
    }
    
    // ============ PUBLIC METHODS ============
    
    /**
     * Called by parent to trigger save
     */
    @api
    triggerSave() {
        // Validate and highlight ALL invalid fields
        const isValid = this.validateAndHighlightAllFields();
        
        if (isValid) {
            this.dispatchEvent(new CustomEvent('sectionsave', {
                detail: {
                    section: 'precheck',
                    data: { ...this._localData }
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
        
        // Validate inputs
        const inputs = this.template.querySelectorAll('lightning-input');
        inputs.forEach(input => {
            const fieldValid = input.reportValidity();
            if (!fieldValid) {
                allValid = false;
            }
        });
        
        return allValid;
    }
    
    validateSection() {
        // No required fields in this section now (hierarchy status removed)
        // Section is always valid
        this.dispatchEvent(new CustomEvent('sectionvalidity', {
            detail: { valid: true }
        }));
        
        return true;
    }
    
    dispatchDataChange(field, value) {
        this.dispatchEvent(new CustomEvent('datachange', {
            detail: { field, value }
        }));
    }
}