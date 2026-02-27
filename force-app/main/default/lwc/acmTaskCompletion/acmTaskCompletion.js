import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import completeACMTask from '@salesforce/apex/HandoverService.completeACMTask';

/**
 * @description ACM Task Completion popup for Internal Handover Call feedback
 */
export default class AcmTaskCompletion extends LightningElement {
    @api recordId; // Task ID
    
    @track isLoading = false;
    @track ihcCompletedTimestamp = null;
    @track documentationQuality = '';
    @track qualityComments = '';
    
    @track errors = {
        completed: false,
        quality: false
    };
    
    // Picklist options for documentation quality
    // Values must match exactly with Salesforce restricted picklist values
    get qualityOptions() {
        return [
            { label: 'OK', value: 'OK' },
            { label: 'Minor Gaps (filled in Internal handover)', value: 'Minor Gaps (filled in Internal handover)' },
            { label: 'Major Gaps (filled in Internal Handover)', value: 'Major Gaps (filled in Internal Handover)' }
        ];
    }
    
    get completedHelpText() {
        return 'Geben Sie das Datum des Internal Handover Calls ein.';
    }
    
    get qualityHelpText() {
        return 'Bewerten Sie die Qualität der Handover-Dokumentation basierend auf dem Internal Handover Call.';
    }
    
    get commentsHelpText() {
        return 'Geben Sie Ihr Feedback zur Handover-Dokumentation ein (max. 3 Sätze).';
    }
    
    get commentsCharacterCount() {
        return (this.qualityComments || '').length;
    }
    
    get commentsCounterClass() {
        const count = this.commentsCharacterCount;
        if (count > 255) {
            return 'slds-text-color_error slds-text-body_small slds-text-align_right slds-m-top_xx-small';
        } else if (count > 230) {
            return 'slds-text-color_weak slds-text-body_small slds-text-align_right slds-m-top_xx-small';
        }
        return 'slds-text-color_weak slds-text-body_small slds-text-align_right slds-m-top_xx-small';
    }
    
    handleCompletedChange(event) {
        this.ihcCompletedTimestamp = event.target.value;
        this.errors.completed = false;
    }
    
    handleQualityChange(event) {
        this.documentationQuality = event.detail.value;
        this.errors.quality = false;
    }
    
    handleCommentsChange(event) {
        this.qualityComments = event.target.value;
    }
    
    validateForm() {
        let isValid = true;
        
        this.errors = {
            completed: false,
            quality: false
        };
        
        if (!this.ihcCompletedTimestamp) {
            this.errors.completed = true;
            isValid = false;
        }
        
        if (!this.documentationQuality) {
            this.errors.quality = true;
            isValid = false;
        }
        
        return isValid;
    }
    
    // Submit handler
    async handleSubmit() {
        if (!this.validateForm()) {
            this.showToast('Fehler', 'Bitte füllen Sie alle Pflichtfelder aus.', 'error');
            return;
        }
        
        this.isLoading = true;
        
        try {
            const result = await completeACMTask({
                taskId: this.recordId,
                ihcScheduledTimestamp: null,
                ihcCompletedTimestamp: this.ihcCompletedTimestamp,
                documentationQuality: this.documentationQuality,
                qualityComments: this.qualityComments
            });
            
            if (result.success) {
                this.showToast('Erfolg', 'Internal Handover Call erfolgreich abgeschlossen!', 'success');
                
                // Notify Lightning that the record has been updated (lightweight refresh)
                notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                
                // Close the action and let the Aura wrapper handle the view refresh
                this.closeAction();
            } else {
                this.showToast('Fehler', result.message, 'error');
            }
        } catch (error) {
            this.showToast('Fehler', error.body?.message || 'Fehler beim Abschließen der Aufgabe.', 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    // Cancel handler
    handleCancel() {
        this.closeAction();
    }
    
    // Close the action panel (dispatch event for Aura wrapper)
    closeAction() {
        // Dispatch custom event for Aura wrapper to close the modal
        this.dispatchEvent(new CustomEvent('close'));
    }
    
    // Toast helper
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }
}