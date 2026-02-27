import { LightningElement, api } from 'lwc';

/**
 * @description Review & Submit Section
 * Displays summary of all entered data before final submission
 */
export default class HandoverSectionReviewSubmit extends LightningElement {
    @api customer360Data = {};
    @api autoPulledContext = {};
    
    // ============ COMPUTED PROPERTIES ============
    
    // Pre-check Summary - Account Hierarchy
    get ultimateParentAccount() {
        return this.autoPulledContext.ultimateParentAccount || '-';
    }
    
    get parentAccountName() {
        return this.autoPulledContext.parentAccountName || '-';
    }
    
    get gtmMotion() {
        return this.autoPulledContext.gtmMotion || '-';
    }
    
    get employees() {
        const val = this.customer360Data.employees;
        return val !== null && val !== undefined ? val.toLocaleString('de-DE') : '-';
    }
    
    get openJobs() {
        const val = this.customer360Data.openJobs;
        return val !== null && val !== undefined ? val.toLocaleString('de-DE') : '-';
    }
    
    get estimatedWalletSize() {
        const val = this.customer360Data.estimatedWalletSize;
        if (val !== null && val !== undefined) {
            return new Intl.NumberFormat('de-DE', { 
                style: 'currency', 
                currency: 'EUR' 
            }).format(val);
        }
        return '-';
    }
    
    // Contact Summary
    get strategicContactName() {
        const first = this.customer360Data.strategicContactFirstName || '';
        const last = this.customer360Data.strategicContactLastName || '';
        return `${first} ${last}`.trim() || '-';
    }
    
    get strategicContactEmail() {
        return this.customer360Data.strategicContactEmail || '-';
    }
    
    get strategicContactTitle() {
        return this.customer360Data.strategicContactTitle || '-';
    }
    
    get operationalContactName() {
        const first = this.customer360Data.operationalContactFirstName || '';
        const last = this.customer360Data.operationalContactLastName || '';
        return `${first} ${last}`.trim() || '-';
    }
    
    get operationalContactEmail() {
        return this.customer360Data.operationalContactEmail || '-';
    }
    
    get operationalContactTitle() {
        return this.customer360Data.operationalContactTitle || '-';
    }
    
    // Notes Summary
    get customerGoals() {
        return this.customer360Data.customerGoals || '-';
    }
    
    get risks() {
        return this.customer360Data.risks || '-';
    }
    
    get relationshipRating() {
        const rating = this.customer360Data.relationshipRating;
        return rating ? `${rating} / 10` : '-';
    }
    
    get relationshipReason() {
        return this.customer360Data.relationshipReason || '-';
    }
    
    get keyLogistics() {
        return this.customer360Data.keyLogistics || '-';
    }
    
    get dos() {
        return this.customer360Data.dos || '-';
    }
    
    get donts() {
        return this.customer360Data.donts || '-';
    }
    
    get other() {
        return this.customer360Data.other || '-';
    }
    
    // ============ EVENT HANDLERS ============
    
    handleSubmit() {
        this.dispatchEvent(new CustomEvent('submithandover'));
    }
}