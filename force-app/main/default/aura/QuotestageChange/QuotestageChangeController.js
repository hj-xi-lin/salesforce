({  
	openModal:function(component, event, helper) {
    var changeType = event.getParams().changeType;
        if (changeType === "CHANGED" && (('Status' in event.getParams().changedFields))) {
            var newStatus = event.getParams().changedFields.Status.value;
            var oldStatus = event.getParams().changedFields.Status.oldValue;
            if(newStatus == 'Sent' && oldStatus == 'Draft'){
                console.log('open pop up');
                 var action1 = component.get('c.getOwner');
                action1.setParams({
                    quoteID: component.get("v.recordId")
                });
                action1.setCallback(this, function(response) {
                    var state = response.getState();
                    var data = response.getReturnValue();
                    if(response.getState() == "SUCCESS"){
                        console.log('data',data); 
                        if(data == true){
                            component.set("v.openPopup",true);
                            var openPopup = component.get("v.openPopup");
                            console.log('openPopup::',openPopup);
                        }
                    } 
                });
                $A.enqueueAction(action1);
            }
        }
	},
    
    handleProceed:function(component, event, helper) {
        var action1 = component.get('c.sendDocumentsToEmail');
        action1.setParams({
            quoteID: component.get("v.recordId")
        });
        action1.setCallback(this, function(response) {
            var state = response.getState();
            var data = response.getReturnValue();
            if(response.getState() == "SUCCESS"){
                component.set('v.openPopup',false);
                $A.get('e.force:refreshView').fire();         
            } 
        });
        $A.enqueueAction(action1);
    },
    
    handleCancel:function(component, event, helper) {
        var action1 = component.get('c.changeStage');
        action1.setParams({
            quoteID: component.get("v.recordId")
        });
        action1.setCallback(this, function(response) {
            var state = response.getState();
            var data = response.getReturnValue();
            if(response.getState() == "SUCCESS"){
                component.set('v.openPopup',false);
                $A.get('e.force:refreshView').fire();
            } 
        });
        $A.enqueueAction(action1);
    }
})