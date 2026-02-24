public class CampaignMemberTriggerHandler {
    public static void runTrigger(){
        if(trigger.isInsert && Trigger.isBefore){
            onBeforeInsert(Trigger.New);
        }
        else if(Trigger.isUpdate && Trigger.isAfter){
            onAfterUpdate(Trigger.New,(Map<Id,CampaignMember>)Trigger.oldMap);
        }
    }
    private static void onBeforeInsert(List<CampaignMember> triggerNew){
        updateRelatedCampaignStatus(triggerNew);
    }
    
    private static void onAfterUpdate(List<CampaignMember> triggerNew, Map<Id,CampaignMember> triggerOldMap){
        
    }
    private static void updateRelatedCampaignStatus(List<CampaignMember> triggerNew){
        Set<Id> lstCampaignId = new Set<Id>();
        Set<Id> lstContactId = new Set<Id>();
        for(CampaignMember objMember : triggerNew){
            if(objMember.CampaignId!=null && objMember.ContactId!=null){
                lstContactId.add(objMember.ContactId);
                lstCampaignId.add(objMember.CampaignId);
            }
        }
        if(!lstCampaignId.isEmpty() && !lstContactId.isEmpty()){
            Set<Id> lstAccountId = new Set<Id>();
            for(Contact objCon : [Select Id, AccountId From Contact Where Id IN:lstContactId]){
                lstAccountId.add(objCon.AccountId);
            }
            if(!lstAccountId.isEmpty()){
                List<CampaignMember> lstMembers = new List<CampaignMember>();
                for(CampaignMember objMember : [SELECT Id,Status, CreatedDate, Campaign.StartDate , Contact.AccountId 
                                                FROM CampaignMember WHERE CampaignId IN: lstCampaignId AND ContactId!=null AND Campaign.Type='E-Mail'])
                {
                    if(objMember.Contact.AccountId!=null && objMember.CreatedDate > objMember.Campaign.StartDate 
                       && lstAccountId.contains(objMember.Contact.AccountId)){
                        objMember.Status = 'Forwarded';
                        lstMembers.add(objMember);
                    }
                }
                System.debug('lstMembers'+lstMembers);
                if(!lstMembers.isEmpty()){
                    UPDATE lstMembers;
                }
            }
        }
    }
}