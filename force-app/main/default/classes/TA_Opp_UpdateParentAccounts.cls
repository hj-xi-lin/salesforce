public with sharing class TA_Opp_UpdateParentAccounts implements TriggerAction.AfterUpdate {
	public void afterUpdate(
		List<Opportunity> newList,
		List<Opportunity> oldList
	) {
		List<Account> toUpdate = new List<Account>();
		Finalizer.registerOpportunities(newList);
		for (Opportunity opp : newList) {
			if (
				TriggerBase.idToNumberOfTimesSeenAfterUpdate.get(opp.Id) == 1 &&
				opp.AccountId != null
			) {
				toUpdate.add(new Account(Id = opp.AccountId));
			}
		}
		update toUpdate;
	}
}