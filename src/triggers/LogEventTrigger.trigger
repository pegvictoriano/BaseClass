/**
* Platform Event Logevent trigger
* @description PRJ1766 - Global utility
*
* @author P.Victoriano
* @date 09/07/2018
*
* @group LPG
* @group-content
*
*/
trigger LogEventTrigger on LogEvent__e (after insert) {
	//TODO: simple insert only
	List<Log__c> logs = new List<Log__c>();
	for (LogEvent__e logEvent : trigger.new) {
		Log__c newLog = new Log__c();
		newLog.CurrentUser__c = logEvent.CurrentUser__c;
		newLog.Input__c = logEvent.Input__c;
		newLog.Message__c = logEvent.Message__c;
		newLog.Priority__c = logEvent.Priority__c;
		newLog.Stack__c = logEvent.Stack__c;
		newLog.Type__c = logEvent.Type__c;
		logs.add(newLog);
	}
	Database.SaveResult[] saveResultList = Database.insert(logs, false);
	System.debug('!!@@##: Log result:' + JSON.serializePretty(saveResultList));
}