/**
 * Abstract class for Trigger Handler
 *
 * @author P. Victoriano
 * @date 18/11/2017
 *
 * @usage
 * 		<code>HandlerClass Sample</code>
 * 		public HandlerClass extends TriggerBase implements ITriggerBase {
 *     		public HandlerClass(){
 *     			//Sample to set Loop count
 *		      	//TriggerDispatcher.setMaxLoopCount(getHandlerName(),2);
 *		       	//Sample bypass / Implement Custom Setting bypass here
 *		        //TriggerDispatcher.bypass(getHandlerName());
 *     		}
 *
 */
public abstract class TriggerBase implements ITriggerBase {
	@TestVisible
	private TriggerContext context;
	/**
	 * Returns a list of the new versions of the sObject records available in insert, update, and undelete triggers
	 */
	//
	public List<sObject> records {get; set;}
	/**
	 * Returns a list of the old versions of the sObject records available in update and delete triggers
	 */
	public List<sObject> oldRecords {get; set;}
	/**
	 * map of IDs to the new versions of the sObject records available in before update, after insert, after update, and after undelete
	 */
	public Map<Id, sObject> newMap {get; set;}
	/**
	 * map of IDs to the old versions of the sObject records available in update and delete triggers
	 */
	public Map<Id, sObject> oldMap  {get; set;}
	/**
	 * Set the Triger context
	 * @return [description]
	 */
	public TriggerBase() {
		this.setTriggerContext();
	}
	// context-specific methods for override
	public virtual void beforeInsert() {}
	public virtual void beforeUpdate() {}
	public virtual void beforeDelete() {}
	public virtual void afterInsert() {}
	public virtual void afterUpdate() {}
	public virtual void afterDelete() {}
	public virtual void afterUndelete() {}
	//Non Overridable methods
	public String getHandlerName() {
		return String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'));
	}
	public String getContext() {
		return context.name();
	}
	/**
	 * default the trigger context based on Trigger Event
	 */
	@TestVisible
	private void setTriggerContext() {
		this.setTriggerContext(null, false);
	}
	/**
	 * Override the Trigger Context Based on Trigger Execution
	 * @param ctx      Trigger Context
	 * @param testMode isRunning test
	 */
	@TestVisible
	private void setTriggerContext(String ctx, Boolean testMode) {
		//Context set
		if (!Trigger.isExecuting && !testMode) {
			return;
		}
		//Pre set Records
		records = (Trigger.isExecuting ? Trigger.new : new List<SObject>());
		newMap = (Trigger.isExecuting ? Trigger.newMap : new Map<Id, SObject>());
		oldRecords = (Trigger.isExecuting ? Trigger.old : new List<SObject>());
		oldMap = (Trigger.isExecuting ? Trigger.oldMap : new Map<Id, SObject>());


		if ((Trigger.isExecuting && Trigger.isBefore && Trigger.isInsert) ||
		        (ctx != null && ctx == 'before insert')) {
			this.context = TriggerContext.BEFORE_INSERT;
		} else if ((Trigger.isExecuting && Trigger.isBefore && Trigger.isUpdate) ||
		           (ctx != null && ctx == 'before update')) {
			this.context = TriggerContext.BEFORE_UPDATE;
		} else if ((Trigger.isExecuting && Trigger.isBefore && Trigger.isDelete) ||
		           (ctx != null && ctx == 'before delete')) {
			this.context = TriggerContext.BEFORE_DELETE;
		} else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isInsert) ||
		           (ctx != null && ctx == 'after insert')) {
			this.context = TriggerContext.AFTER_INSERT;
		} else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isUpdate) ||
		           (ctx != null && ctx == 'after update')) {
			this.context = TriggerContext.AFTER_UPDATE;
		} else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isDelete) ||
		           (ctx != null && ctx == 'after delete')) {
			this.context = TriggerContext.AFTER_DELETE;
		} else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isUndelete) ||
		           (ctx != null && ctx == 'after undelete')) {
			this.context = TriggerContext.AFTER_UNDELETE;
		}
	}
	@TestVisible
	private enum TriggerContext {
		BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,
		AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE,
		AFTER_UNDELETE
	}
}
