({
    handleClose: function(component, event, helper) {
        // Close the quick action modal
        $A.get("e.force:closeQuickAction").fire();
        
        // Refresh the view to show updated Task data (lightweight Lightning refresh)
        $A.get("e.force:refreshView").fire();
    }
})