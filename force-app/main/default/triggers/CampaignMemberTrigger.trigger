trigger CampaignMemberTrigger on CampaignMember (before insert, after Update) {
    CampaignMemberTriggerHandler.runTrigger();
}