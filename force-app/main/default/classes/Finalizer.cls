public with sharing class Finalizer implements Queueable, TriggerAction.DmlFinalizer {
	private static List<Opportunity> toProcess = new List<Opportunity>();
	private List<Opportunity> currentlyProcessing;

	public static void registerOpportunities(List<Opportunity> toRecalculate) {
		toProcess.addAll(toRecalculate);
	}

	public void execute(FinalizerHandler.Context context) {
		System.debug('Finalizing!');
		if (!toProcess.isEmpty()) {
			this.currentlyProcessing = toProcess;
			System.enqueueJob(this);
		}
	}

	public void execute(System.QueueableContext qc) {
		System.debug(
			'Processing ' + this.currentlyProcessing.size() + ' Opportunities'
		);
	}
}