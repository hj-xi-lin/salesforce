/**
 * @description Invocable Action for Flows: updates Customer_360__c.Time_To_ACM_Assignment__c when an Account is assigned to an ACM.
 * Call from the "Create ACM Task for Pilot Handover" flow after updating Timestamp_ACM_Assignment__c on the Account.
 */
public with sharing class C360TimeToACMAssignmentAction {
    
    @InvocableMethod(label='Calculate Time to ACM Assignment'
                     description='Updates Customer 360 Time to ACM Assignment when Account is assigned to ACM. Call from Create ACM Task for Pilot Handover flow.')
    public static void calculateTimeToACMAssignment(List<TimeToACMAssignmentRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }
        List<Id> accountIds = new List<Id>();
        for (TimeToACMAssignmentRequest req : requests) {
            if (req != null && req.accountId != null) {
                accountIds.add(req.accountId);
            }
        }
        if (!accountIds.isEmpty()) {
            HandoverService.calculateTimeToACMAssignmentForAccounts(accountIds);
        }
    }
    
    public class TimeToACMAssignmentRequest {
        @InvocableVariable(required=true label='Account Id' description='The Account that was assigned to an ACM')
        public Id accountId;
    }
}