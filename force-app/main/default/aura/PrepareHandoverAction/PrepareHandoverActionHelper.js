({
    initFromTask: function(component, taskId) {
        var action = component.get("c.checkHandoverStatus");
        action.setParams({ taskId: taskId });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var status = response.getReturnValue();
                
                if (status && status.isCompleted) {
                    component.set("v.isCompleted", true);
                    component.set("v.customer360Url", status.customer360Url);
                    component.set("v.accountName", status.accountName);
                    component.set("v.isLoading", false);
                } else {
                    this.openWizard(component, taskId, "Task", taskId);
                }
            } else {
                console.error("Error checking status:", response.getError());
                this.openWizard(component, taskId, "Task", taskId);
            }
        });
        
        $A.enqueueAction(action);
    },
    
    initFromOpportunity: function(component, opportunityId) {
        var self = this;
        var action = component.get("c.resolveHandoverTask");
        action.setParams({ opportunityId: opportunityId });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var status = response.getReturnValue();
                
                if (status && status.isCompleted) {
                    component.set("v.isCompleted", true);
                    component.set("v.customer360Url", status.customer360Url);
                    component.set("v.accountName", status.accountName);
                    component.set("v.isLoading", false);
                } else {
                    self.openWizard(component, status.taskId, "Opportunity", opportunityId);
                }
            } else {
                var errors = response.getError();
                var message = (errors && errors[0] && errors[0].message) 
                    ? errors[0].message 
                    : "Fehler beim Laden des Handover-Tasks.";
                component.set("v.hasError", true);
                component.set("v.errorMessage", message);
                component.set("v.isLoading", false);
            }
        });
        
        $A.enqueueAction(action);
    },
    
    openWizard: function(component, taskId, sourceObjectApiName, sourceRecordId) {
        var baseUrl = window.location.origin;
        
        var wizardUrl = baseUrl + '/apex/HandoverWizardPage?c__recordId=' + taskId 
            + '&c__objectApiName=Task'
            + '&c__sourceObjectApiName=' + sourceObjectApiName 
            + '&c__sourceRecordId=' + sourceRecordId;
        
        var wizardWindow = window.open(wizardUrl, '_blank');
        window.__handoverWizardWindow = wizardWindow;
        
        if (window.__handoverFocusHandler) {
            window.removeEventListener('focus', window.__handoverFocusHandler);
        }
        
        window.__handoverFocusHandler = function() {
            if (window.__handoverWizardWindow && window.__handoverWizardWindow.closed) {
                window.removeEventListener('focus', window.__handoverFocusHandler);
                window.__handoverFocusHandler = null;
                window.__handoverWizardWindow = null;
                window.location.reload();
            }
        };
        window.addEventListener('focus', window.__handoverFocusHandler);
        
        var closeAction = $A.get("e.force:closeQuickAction");
        window.setTimeout(
            $A.getCallback(function() {
                closeAction.fire();
            }), 
            300
        );
    }
})