({
    doInit: function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var sObjectName = component.get("v.sObjectName");
        
        if (sObjectName === "Opportunity") {
            helper.initFromOpportunity(component, recordId);
        } else {
            helper.initFromTask(component, recordId);
        }
    },
    
    handleViewDocumentation: function(component, event, helper) {
        var customer360Url = component.get("v.customer360Url");
        
        if (customer360Url) {
            var navService = component.find("navService");
            var pageRef = {
                type: "standard__recordPage",
                attributes: {
                    recordId: customer360Url.split("/").pop().split("?")[0],
                    objectApiName: "Customer_360__c",
                    actionName: "view"
                }
            };
            
            navService.navigate(pageRef);
        }
        
        var closeAction = $A.get("e.force:closeQuickAction");
        closeAction.fire();
    }
})