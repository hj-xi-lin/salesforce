import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// Apex methods
import initializeHandover from '@salesforce/apex/HandoverService.initializeHandover';
import saveHandoverData from '@salesforce/apex/HandoverService.saveHandoverData';
import completeHandover from '@salesforce/apex/HandoverService.completeHandover';
import updateTimeSpent from '@salesforce/apex/HandoverService.updateTimeSpent';

/**
 * @description Parent container for the Handover Wizard
 * Manages state, navigation, and data flow between child components
 */
export default class HandoverWizardContainer extends NavigationMixin(LightningElement) {
    @api recordId; // Task ID passed from the launcher
    @api objectApiName; // Task
    @api sourceObjectApiName; // Original object: Task or Opportunity
    @api sourceRecordId; // Original record ID (Opportunity ID when launched from Opportunity)
    
    @track currentStep = 1;
    @track isLoading = true;
    @track isSaving = false;
    @track errorMessage = '';
    @track _isDirty = false;
    @track _toastVisible = false;
    @track _toastData = {};
    
    // IDs for backend operations
    _taskId;
    _accountId;
    _customer360Id;
    
    // Original data for delta comparison
    _originalData = {};
    
    // Time tracking for sections
    _sectionEntryTime = null;
    _currentSectionForTime = null;
    
    // Section validity tracking
    @track sectionValidity = {
        '1': true,   // Pre-check (no required fields now)
        '2': false,  // Notes
        '3': true    // Review is always valid
    };
    
    // Customer 360 record data (editable fields)
    @track customer360Data = {
        // Pre-check - Parent Account (editable)
        parentAccountId: '',
        // Pre-check - Editable Account fields
        employees: null,
        openJobs: null,
        estimatedWalletSize: null,
        // Pre-check - Contact data
        strategicContactId: '',
        strategicContactFirstName: '',
        strategicContactLastName: '',
        strategicContactEmail: '',
        strategicContactPhone: '',
        strategicContactTitle: '',
        operationalContactId: '',
        operationalContactFirstName: '',
        operationalContactLastName: '',
        operationalContactEmail: '',
        operationalContactPhone: '',
        operationalContactTitle: '',
        // Handover Notes
        handoverUrgency: 'Standard',
        customerGoals: '',
        risks: '',
        relationshipRating: null,
        relationshipReason: '',
        keyLogistics: '',
        dos: '',
        donts: '',
        other: ''
    };
    
    // Auto-pulled context (read-only display data)
    @track autoPulledContext = {};
    
    // Bound reference for beforeunload handler
    _boundBeforeUnload;

    // ============ LIFECYCLE HOOKS ============
    
    connectedCallback() {
        this.loadHandoverData();
        
        // Set up browser close warning
        this._boundBeforeUnload = this.handleBeforeUnload.bind(this);
        window.addEventListener('beforeunload', this._boundBeforeUnload);
    }
    
    disconnectedCallback() {
        // Clean up event listener
        if (this._boundBeforeUnload) {
            window.removeEventListener('beforeunload', this._boundBeforeUnload);
        }
    }
    
    // ============ DATA LOADING ============
    
    /**
     * Load handover data from Apex
     */
    async loadHandoverData() {
        this.isLoading = true;
        this.errorMessage = '';
        
        try {
            // Call Apex to get context and create/get Customer_360 record
            const context = await initializeHandover({ taskId: this.recordId });
            
            // Store IDs for later use
            this._taskId = context.taskId;
            this._accountId = context.accountId;
            this._customer360Id = context.customer360Id;
            
            // Set auto-pulled context (read-only display data)
            this.autoPulledContext = {
                // Account data
                accountId: context.accountId,
                accountName: context.accountName,
                accountUrl: context.accountUrl,
                employees: context.employees,
                openJobs: context.openJobs,
                estimatedWalletSize: context.estimatedWalletSize,
                gtmMotion: context.gtmMotion,
                
                // Account hierarchy
                parentAccountId: context.parentAccountId,
                parentAccountName: context.parentAccountName,
                ultimateParentAccount: context.ultimateParentAccount,
                
                // Opportunity context for header (if available)
                opportunityId: context.opportunityId,
                opportunityCloseDate: context.opportunityCloseDate || '',
                opportunityAmount: context.opportunityAmount || 0,
                productSold: context.productSold || '',
                
                // Contact data
                strategicContact: context.strategicContact,
                operationalContact: context.operationalContact
            };
            
            // Initialize editable fields with auto-pulled values AND previously saved data
            this.customer360Data = {
                ...this.customer360Data,
                parentAccountId: context.parentAccountId || '',
                employees: context.employees,
                openJobs: context.openJobs,
                estimatedWalletSize: context.estimatedWalletSize,
                strategicContactId: context.strategicContact?.id || '',
                strategicContactFirstName: context.strategicContact?.firstName || '',
                strategicContactLastName: context.strategicContact?.lastName || '',
                strategicContactEmail: context.strategicContact?.email || '',
                strategicContactPhone: context.strategicContact?.phone || '',
                strategicContactTitle: context.strategicContact?.title || '',
                operationalContactId: context.operationalContact?.id || '',
                operationalContactFirstName: context.operationalContact?.firstName || '',
                operationalContactLastName: context.operationalContact?.lastName || '',
                operationalContactEmail: context.operationalContact?.email || '',
                operationalContactPhone: context.operationalContact?.phone || '',
                operationalContactTitle: context.operationalContact?.title || '',
                // Load previously saved notes data for resume
                handoverUrgency: context.handoverUrgency || 'Standard',
                customerGoals: context.customerGoals || '',
                risks: context.risks || '',
                relationshipRating: context.relationshipRating,
                relationshipReason: context.relationshipReason || '',
                keyLogistics: context.keyLogistics || '',
                dos: context.dos || '',
                donts: context.donts || '',
                other: context.other || ''
            };
            
            // Resume from saved step
            this.currentStep = this.stepNameToNumber(context.currentWizardStep);
            
            if (context.customerGoals && context.keyLogistics && context.dos && context.donts
                && context.risks && context.relationshipRating && context.relationshipReason) {
                this.sectionValidity['2'] = true;
            }
            
            // Store original data for delta comparison
            this._originalData = JSON.parse(JSON.stringify(this.customer360Data));
            
            this._isDirty = false; // Reset dirty flag after loading
            
            // Start tracking time on initial section
            this.startSectionTimer();
            
        } catch (error) {
            this.errorMessage = error.body?.message || error.message || 'Fehler beim Laden der Handover-Daten';
            this.showToast('Fehler', this.errorMessage, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    // ============ COMPUTED PROPERTIES ============
    
    get isNotLoading() {
        return !this.isLoading;
    }
    
    get wizardTitle() {
        return 'Handover Documentation';
    }
    
    get hasError() {
        return !!this.errorMessage;
    }
    
    // ============ CONTEXT HEADER COMPUTED PROPERTIES ============
    
    get contextAccountName() {
        return this.autoPulledContext.accountName || '-';
    }
    
    get contextAccountUrl() {
        return this.autoPulledContext.accountUrl || '#';
    }
    
    get contextCloseDate() {
        const dateStr = this.autoPulledContext.opportunityCloseDate;
        if (!dateStr) return '-';
        
        try {
            const date = new Date(dateStr);
            return date.toLocaleDateString('de-DE', {
                day: '2-digit',
                month: '2-digit',
                year: 'numeric'
            });
        } catch (e) {
            return dateStr;
        }
    }
    
    get contextAmount() {
        const amount = this.autoPulledContext.opportunityAmount;
        if (amount === null || amount === undefined) return '-';
        
        return new Intl.NumberFormat('de-DE', {
            style: 'currency',
            currency: 'EUR',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(amount);
    }
    
    get contextProductSold() {
        return this.autoPulledContext.productSold || '-';
    }
    
    // ============ STEP VISIBILITY GETTERS ============
    
    get currentStepValue() {
        return this.currentStep.toString();
    }
    
    get isPrecheck() {
        return this.currentStep === 1;
    }
    
    get isNotes() {
        return this.currentStep === 2;
    }
    
    get isReview() {
        return this.currentStep === 3;
    }
    
    // ============ NAVIGATION BUTTON VISIBILITY ============
    
    get showBackButton() {
        return this.currentStep > 1;
    }
    
    get showNextButton() {
        return this.currentStep < 3;
    }
    
    get showSubmitButton() {
        return this.currentStep === 3;
    }
    
    get nextButtonLabel() {
        return 'Weiter';
    }
    
    get backButtonLabel() {
        return 'Zurück';
    }
    
    get submitButtonLabel() {
        return 'Handover abschließen';
    }
    
    get saveDraftButtonLabel() {
        return 'Entwurf speichern';
    }
    
    get isSaveDraftDisabled() {
        return !this._isDirty || this.isSaving || this.isLoading;
    }
    
    get isNavigationDisabled() {
        return this.isSaving || this.isLoading;
    }
    
    get currentStepKey() {
        return this.currentStep.toString();
    }
    
    get isCurrentStepValid() {
        return this.sectionValidity[this.currentStepKey];
    }
    
    // ============ EVENT HANDLERS ============
    
    /**
     * Handle browser beforeunload event - warn about unsaved changes
     */
    handleBeforeUnload(event) {
        if (this._isDirty) {
            event.preventDefault();
            event.returnValue = ''; // Required for Chrome
            return ''; // Required for some browsers
        }
    }
    
    /**
     * Handle account link click - open in new tab
     */
    handleAccountLinkClick(event) {
        event.preventDefault();
        const url = this.contextAccountUrl;
        if (url && url !== '#') {
            window.open(url, '_blank');
        }
    }
    
    /**
     * Handle section save event from child components
     */
    handleSectionSave(event) {
        const { section, data } = event.detail;
        
        // Merge data into customer360Data
        this.customer360Data = { ...this.customer360Data, ...data };
        
        // Save to backend and navigate
        this.saveAndNavigate();
    }
    
    /**
     * Handle section validity change from child components
     */
    handleSectionValidity(event) {
        const { valid } = event.detail;
        this.sectionValidity[this.currentStepKey] = valid;
    }
    
    /**
     * Handle data change from child components (for real-time updates)
     */
    handleDataChange(event) {
        const { field, value } = event.detail;
        this.customer360Data = { ...this.customer360Data, [field]: value };
        this._isDirty = true; // Mark as dirty when data changes
    }
    
    /**
     * Handle Next button click
     */
    handleNext() {
        // Get the current child component and trigger save
        const currentChild = this.getCurrentChildComponent();
        if (currentChild && typeof currentChild.triggerSave === 'function') {
            currentChild.triggerSave();
        } else {
            // If no save needed, just navigate
            this.saveAndNavigate();
        }
    }
    
    /**
     * Handle Back button click
     */
    handleBack() {
        this.navigateBack();
    }
    
    /**
     * Handle Save Draft button click
     */
    handleSaveDraft() {
        this.saveData(false); // Save without navigating
    }
    
    /**
     * Handle Submit button click
     */
    async handleSubmit() {
        this.isLoading = true;
        
        // Save time spent on current section before completing
        this.saveTimeSpentOnCurrentSection();
        
        try {
            const { request: saveRequest } = this.buildSaveRequest(null, true);
            saveRequest.documentationStatus = 'Completed';
            
            // Call Apex to complete handover
            const result = await completeHandover({ dataMap: saveRequest });
            
            if (result.success) {
                this._isDirty = false;
                this.showToast('Erfolg', 'Handover erfolgreich abgeschlossen!', 'success');
                
                // Refresh the original Task tab and close the wizard tab
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(() => {
                    this.closeWizardAndRefreshTask();
                }, 1500);
            } else {
                this.showToast('Fehler', result.message, 'error');
            }
        } catch (error) {
            this.showToast('Fehler', error.body?.message || 'Fehler beim Abschließen des Handovers', 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    /**
     * Close the wizard tab and refresh the original source tab.
     * The opener (Aura Quick Action) has set up a focus listener that detects
     * when this wizard tab closes and automatically reloads the source page.
     */
    closeWizardAndRefreshTask() {
        window.close();
        
        // Fallback: if window.close() doesn't work (some browsers block it),
        // navigate to the source record (Task or Opportunity) in the current tab
        const targetRecordId = this.sourceRecordId || this._taskId;
        const targetObjectApiName = this.sourceObjectApiName || 'Task';
        
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            if (!window.closed) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: targetRecordId,
                        objectApiName: targetObjectApiName,
                        actionName: 'view'
                    }
                });
            }
        }, 100);
    }
    
    // ============ SAVE LOGIC ============
    
    /**
     * Save data to backend and navigate to next step
     */
    saveAndNavigate() {
        const nextStep = this.currentStep < 3 ? this.currentStep + 1 : this.currentStep;
        const nextStepName = this.stepNumberToName(nextStep);
        this.saveData(true, nextStepName);
    }
    
    /**
     * Save data to backend
     * @param {boolean} navigateAfterSave - Whether to navigate to next step after save
     * @param {string} nextStepName - The step name to save (for tracking)
     */
    async saveData(navigateAfterSave, nextStepName = null) {
        const { request: saveRequest, hasChanges } = this.buildSaveRequest(nextStepName, false);
        
        const isStepTransition = navigateAfterSave && 
            saveRequest.previousWizardStep !== saveRequest.currentWizardStep;
        
        if (!hasChanges && !isStepTransition) {
            this._isDirty = false;
            if (navigateAfterSave) {
                this.navigateNext();
            } else {
                this.showToast('Info', 'Keine Änderungen zu speichern', 'info');
            }
            return;
        }
        
        this.isSaving = true;
        
        try {
            saveRequest.documentationStatus = 'In Progress';
            
            // Call Apex to save (includes step transition timestamps)
            const result = await saveHandoverData({ dataMap: saveRequest });
            
            if (result.success) {
                // Update original data to reflect saved state
                this._originalData = JSON.parse(JSON.stringify(this.customer360Data));
                this._isDirty = false;
                
                if (navigateAfterSave) {
                    if (hasChanges) {
                        this.showToast('Erfolg', 'Daten gespeichert', 'success');
                    }
                    this.navigateNext();
                } else {
                    this.showToast('Erfolg', 'Entwurf wurde gespeichert', 'success');
                }
            } else {
                this.showToast('Fehler', result.message, 'error');
            }
        } catch (error) {
            this.showToast('Fehler', error.body?.message || 'Fehler beim Speichern der Daten', 'error');
        } finally {
            this.isSaving = false;
        }
    }
    
    /**
     * Build save request object for Apex - only includes changed fields (delta save)
     * @param {string} nextStepName - The step user is navigating to (for tracking)
     * @param {boolean} forceAll - If true, include all fields (for complete handover)
     */
    buildSaveRequest(nextStepName = null, forceAll = false) {
        const currentStepName = this.stepNumberToName(this.currentStep);
        const request = {
            taskId: this._taskId,
            accountId: this._accountId,
            customer360Id: this._customer360Id,
            currentWizardStep: nextStepName || currentStepName,
            previousWizardStep: currentStepName
        };
        
        if (forceAll) {
            return {
                request: {
                    ...request,
                    employees: this.customer360Data.employees,
                    openJobs: this.customer360Data.openJobs,
                    parentAccountId: this.customer360Data.parentAccountId || null,
                    strategicContactId: this.customer360Data.strategicContactId || null,
                    operationalContactId: this.customer360Data.operationalContactId || null,
                    handoverUrgency: this.customer360Data.handoverUrgency,
                    customerGoals: this.customer360Data.customerGoals,
                    risks: this.customer360Data.risks,
                    relationshipRating: this.customer360Data.relationshipRating,
                    relationshipReason: this.customer360Data.relationshipReason,
                    keyLogistics: this.customer360Data.keyLogistics,
                    dos: this.customer360Data.dos,
                    donts: this.customer360Data.donts,
                    other: this.customer360Data.other
                },
                hasChanges: true
            };
        }
        
        const fieldsToCheck = [
            'employees', 'openJobs', 'parentAccountId',
            'strategicContactId', 'operationalContactId',
            'handoverUrgency', 'customerGoals', 'risks', 'relationshipRating', 'relationshipReason',
            'keyLogistics', 'dos', 'donts', 'other'
        ];
        
        let hasChanges = false;
        for (const field of fieldsToCheck) {
            const currentVal = this.customer360Data[field];
            const originalVal = this._originalData[field];
            
            const currentNormalized = currentVal === '' || currentVal === undefined ? null : currentVal;
            const originalNormalized = originalVal === '' || originalVal === undefined ? null : originalVal;
            
            if (currentNormalized !== originalNormalized) {
                request[field] = currentVal || null;
                hasChanges = true;
            }
        }
        
        return { request, hasChanges };
    }
    
    // ============ NAVIGATION LOGIC ============
    
    /**
     * Navigate to next step
     */
    navigateNext() {
        if (this.currentStep < 3) {
            // Save time spent on current section before navigating
            this.saveTimeSpentOnCurrentSection();
            this.currentStep++;
            // Start tracking time on new section
            this.startSectionTimer();
        }
    }
    
    /**
     * Navigate to previous step
     */
    navigateBack() {
        if (this.currentStep > 1) {
            // Save time spent on current section before navigating
            this.saveTimeSpentOnCurrentSection();
            this.currentStep--;
            // Start tracking time on new section
            this.startSectionTimer();
        }
    }
    
    /**
     * Start timer for current section
     */
    startSectionTimer() {
        this._sectionEntryTime = Date.now();
        this._currentSectionForTime = this.stepNumberToName(this.currentStep);
    }
    
    /**
     * Save time spent on current section (async, non-blocking)
     */
    saveTimeSpentOnCurrentSection() {
        if (!this._sectionEntryTime || !this._customer360Id) {
            return;
        }
        
        const sectionName = this._currentSectionForTime;
        // Only track Pre-check and Notes sections
        if (sectionName !== 'Pre-check' && sectionName !== 'Notes') {
            return;
        }
        
        const timeSpentMs = Date.now() - this._sectionEntryTime;
        const timeSpentMinutes = Math.round(timeSpentMs / 60000); // Convert to minutes
        
        // Only save if at least 1 minute spent
        if (timeSpentMinutes >= 1) {
            const sectionKey = sectionName === 'Pre-check' ? 'PreCheck' : 'Notes';
            // Fire and forget - don't block navigation
            updateTimeSpent({
                customer360Id: this._customer360Id,
                sectionName: sectionKey,
                minutesSpent: timeSpentMinutes
            }).catch(() => {});
        }
        
        // Reset timer
        this._sectionEntryTime = null;
    }
    
    // ============ UTILITY METHODS ============
    
    /**
     * Get reference to current child component
     */
    getCurrentChildComponent() {
        if (this.isPrecheck) {
            return this.template.querySelector('c-handover-section-pre-checks');
        } else if (this.isNotes) {
            return this.template.querySelector('c-handover-section-notes');
        }
        return null;
    }
    
    /**
     * Show toast notification
     */
    get toastContainerClass() {
        return 'custom-toast-container';
    }

    get toastClass() {
        const base = 'custom-toast';
        const v = this._toastData.variant || 'info';
        return `${base} custom-toast_${v}`;
    }

    get toastIcon() {
        const map = { success: 'utility:success', error: 'utility:error', warning: 'utility:warning', info: 'utility:info' };
        return map[this._toastData.variant] || 'utility:info';
    }

    showToast(title, message, variant) {
        this._toastData = { title, message, variant };
        this._toastVisible = true;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => { this._dismissToast(); }, 4000);
    }

    _dismissToast() {
        this._toastVisible = false;
    }
    
    /**
     * Convert step name to step number
     * @param {string} stepName - The step name (Pre-check, Notes, Review)
     * @returns {number} The step number (1, 2, 3)
     */
    stepNameToNumber(stepName) {
        const stepMap = {
            'Pre-check': 1,
            'Notes': 2,
            'Review': 3
        };
        return stepMap[stepName] || 1;
    }
    
    /**
     * Convert step number to step name
     * @param {number} stepNumber - The step number (1, 2, 3)
     * @returns {string} The step name (Pre-check, Notes, Review)
     */
    stepNumberToName(stepNumber) {
        const stepMap = {
            1: 'Pre-check',
            2: 'Notes',
            3: 'Review'
        };
        return stepMap[stepNumber] || 'Pre-check';
    }
}