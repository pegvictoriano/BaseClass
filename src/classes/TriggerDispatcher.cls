/**
 * Modified From kevinohara80/sfdc-trigger-framework
 *
 * @author P. Victoriano
 * @date 18/11/2017
 *
 * @usage
 *
 * 		<code>Trigger Sample</code>
 * 		trigger SObjectTrigger on SObject (after delete,
 * 						after insert,
 * 						after undelete,
 * 						after update,
 * 		    			before delete,
 * 		    			before insert,
 * 		    			before update) {
 *			run(new HandlerClass());
 *	  	}
 *
 **/
public class TriggerDispatcher {
	// static map of handlername, times run() was invoked
	@TestVisible
	private static Map<String, LoopCount> loopCountMap {get; set;}
	@TestVisible
	private static Set<String> bypassedHandlers {get; set;}

	// static initialization
	static {
		loopCountMap = new Map<String, LoopCount>();
		bypassedHandlers = new Set<String>();
	}
	/**
	 * Calls appropriate TriggerBase methods
	 * @param handler [implements ITriggerBase]
	 */
	public static void run(ITriggerBase handler) {
		if (handler == null) {
			throw new TriggerException('Handler exception');
		}
		String handlerName = handler.getHandlerName();
		//addToLoopCount(handlerName);
		// Check to see if the trigger has been disabled. If it has, return
		if (bypassedHandlers != null && bypassedHandlers.contains(handlerName)) {
			System.debug('!!@@##: Handler Bypassed: ' + handlerName);
			return;
		}
		addToLoopCount(handlerName);
		//
		if (handler.getContext() == 'BEFORE_INSERT') {
			handler.beforeInsert();
		}
		if (handler.getContext() == 'BEFORE_UPDATE') {
			handler.beforeUpdate();
		}
		if (handler.getContext() == 'BEFORE_DELETE') {
			handler.beforeDelete();
		}
		if (handler.getContext() == 'AFTER_INSERT') {
			handler.afterInsert();
		}
		if (handler.getContext() == 'AFTER_UPDATE') {
			handler.afterUpdate();
		}
		if (handler.getContext() == 'AFTER_DELETE') {
			handler.afterDelete();
		}
		if (handler.getContext() == 'AFTER_UNDELETE') {
			handler.afterUndelete();
		}
	}
	/**
	 * bypass Triggerhandler
	 */
	public static void bypass(String handlerName) {
		bypassedHandlers.add(handlerName);
	}
	/**
	 * Removes bypass TriggerHandler
	 */
	public static void clearBypass(String handlerName) {
		bypassedHandlers.remove(handlerName);
	}
	/**
	 * Checks if TriggerHandler is bypassed
	 */
	public static Boolean isBypassed(String handlerName) {
		return bypassedHandlers.contains(handlerName);
	}
	/**
	 * removes all Bypassed TriggerHandlers
	 */
	public static void clearAllBypasses() {
		bypassedHandlers.clear();
	}
	/**
	 * Sets triggerhandlers max loop count
	 */
	public static void setMaxLoopCount(String handlerName, Integer max) {
		if (!loopCountMap.containsKey(handlerName)) {
			loopCountMap.put(handlerName, new LoopCount(max));
		} else {
			loopCountMap.get(handlerName).setMax(max);
		}
	}
	/**
	 * removes max loop count for trigger handler
	 */
	public static void clearMaxLoopCount(String handlerName) {
		loopCountMap.remove(handlerName);
	}

	@TestVisible
	private static void addToLoopCount(String handlerName) {
		if (loopCountMap.containsKey(handlerName)) {
			Boolean exceeded = loopCountMap.get(handlerName).increment();
			if (exceeded) {
				Integer max = loopCountMap.get(handlerName).max;
				throw new TriggerException('Maximum loop count of ' + String.valueOf(max) + ' reached in ' + handlerName);
			}
		}
	}
	// inner class for managing the loop count per handler
	@TestVisible
	private class LoopCount {
		private Integer max;
		private Integer count;

		public LoopCount() {
			this.max = 5;
			this.count = 0;
		}

		public LoopCount(Integer max) {
			this.max = max;
			this.count = 0;
		}

		public Boolean increment() {
			this.count++;
			return this.exceeded();
		}

		public Boolean exceeded() {
			if (this.max < 0) {
				return false;
			}
			if (this.count > this.max) {
				return true;
			}
			return false;
		}

		public Integer getMax() {
			return this.max;
		}

		public Integer getCount() {
			return this.count;
		}

		public void setMax(Integer max) {
			this.max = max;
		}
	}
	// exception class
	public class TriggerException extends Exception {}
}