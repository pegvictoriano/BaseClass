/**
 * @description Custom Persistence Logging Utility using Platform Events
 * Request counts as an API request
 *
 * @author P. Victoriano
 * @date 18/11/2017 
 **/
public class LogUtilityException extends Exception {
	//TODO finalize Generic Message
	static final String SYSMSG = 'Exception occured. Please contact System adminstrator.';
	//dont create logs for these DML Exception types
	static final Set<String> skippedTypes = new Set<String> {
		StatusCode.FAILED_ACTIVATION.name(),
		StatusCode.STRING_TOO_LONG.name(),
		StatusCode.INVALID_EMAIL_ADDRESS.name(),
		StatusCode.REQUIRED_FIELD_MISSING.name(),
		StatusCode.FIELD_INTEGRITY_EXCEPTION.name(),
		StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION.name(),
		StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION.name()
	};
	/**
	 * Helper to rethrow System Message
	 * @param sCustom Message to throw
	 * @example
	 *	} catch (Exception e) {
	 *		LogUtilityException.logException(e);
	 *		LogUtilityException.throwMSG();
	 *	}
	 */
	public static void throwMSG() {
		throwMSG(SYSMSG);
	}
	/**
	 * Helper to rethrow Custom
	 * @param sCustom String message
	 */
	public static void throwMSG(String sCustom) {
		String str = sCustom;
		throw new LogUtilityException(str);
	}
	public static void throwAura(Exception err, Boolean appendErrMsg) {
		String sMsg = SYSMSG;
		if (appendErrMsg) {
			sMsg = String.format('{0} - {1}', new LIST<String> {SYSMSG, err.getMessage()});
		}
		throw new AuraHandledException(sMsg);
	}
	/**
	 * Formatted Apex Debug Log message
	 * @param Anydatatype_msg Any Object
	 */
	public static void debug(Object Anydatatype_msg) {
		String sMsg = String.format('{0} {1}{2} {3}', new LIST<String> {
			'!!@@##: [',
			getDebugStack(),
			']:',
			String.valueOf(Anydatatype_msg)
		});
		System.debug(sMsg);
	}
	/**
	 * Log a custom trace message
	 * @param stype Type of Log
	 * @param inp   Input Stream
	 * @param msg   Message / output stream
	 */
	public static void logDebug(Object stype, Object inp, Object msg) {
		LogEvent__e nLog = new LogEvent__e();
		nLog.CurrentUser__c = UserInfo.getUserId();
		nLog.Stack__c = getStack();
		nLog.Input__c = String.valueOf(inp);
		nLog.Message__c = String.valueOf(msg);
		nLog.Type__c = String.valueOf(stype);
		nLog.Priority__c = 'INFO';
		//dont log if type is in the list
		if (!skippedTypes.contains(nLog.Type__c)) {
			QueueLogs(nLog);
		}
	}
	/**
	 * Log a custom exception Message
	 * @param stype Type of Log
	 * @param inp   Input Stream
	 * @param msg   Message / output stream
	 */
	public static void logExceptionMSG(Object stype, Object inp, Object msg) {
		LogEvent__e nLog = new LogEvent__e();
		nLog.CurrentUser__c = UserInfo.getUserId();
		nLog.Stack__c = getStack();
		nLog.Input__c = String.valueOf(inp);
		nLog.Message__c = String.valueOf(msg);
		nLog.Type__c = String.valueOf(stype);
		nLog.Priority__c = 'ERROR';
		//dont log if type is in the list
		if (!skippedTypes.contains(nLog.Type__c)) {
			QueueLogs(nLog);
		}
	}
	/**
	 * Log a message from exception object
	 * @param err exception object
	 */
	public static void logException(Exception err) {
		logException(err, '');
	}
	/**
	 * Log a message from exception object
	 * @param err Exception object
	 * @param obj parameter object Id, Key etc
	 */
	public static void logException(Exception err, Object obj) {
		//Added check for FIELD_CUSTOM_VALIDATION_EXCEPTION to return user friendly error.
		Boolean isValRuleError = false;
		String errType = '';
		String errorMsg = err.getMessage();
		if (err.getTypeName() == DmlException.class.getName()) {
			DmlException dmlEx = (DmlException)err;
			errType = dmlEx.getDmlType(0).name();
			if (skippedTypes.contains(errType)) {
				errorMsg = cleanseMessage(errorMsg, errType);
				isValRuleError = true;
			}
		}
		String sInputStream = String.format('{0} {1} : {2}', new LIST<String> {
			String.valueOf(err.getCause()),
			String.valueOf(err.getLineNumber()),
			String.valueOf(obj)
		});
		LogEvent__e nLog = new LogEvent__e();
		nLog.CurrentUser__c = UserInfo.getUserId();
		nLog.Stack__c = getStack();
		nLog.Input__c = sInputStream;
		nLog.Message__c = String.valueOf(err.getMessage());
		nLog.Type__c = String.valueOf(err.getTypeName());
		nLog.Priority__c = 'ERROR';
		//dont log if type is in the list
		if (!skippedTypes.contains(errType) || System.isBatch() || System.isScheduled() || System.isFuture()) {
			QueueLogs(nLog);
		}
		//Since this is a validation rule reThrow message to user
		if (isValRuleError) {
			throw new LogUtilityException(errorMsg);
		}
	}
	/**
	 * Log a message from exception object
	 * @param err       Exception
	 * @param lSobjects List of Sobjects to append Error message
	 */
	public static void logException(Exception err, List<SObject> lSobjects) {
		List<LogEvent__e> listLogs = new List<LogEvent__e>();
		//Added check for FIELD_CUSTOM_VALIDATION_EXCEPTION to return user friendly error.
		String errType = '';
		String errorMsg = err.getMessage();
		if (err.getTypeName() == DmlException.class.getName()) {
			DmlException dmlEx = (DmlException)err;
			errType = dmlEx.getDmlType(0).name();
			//If type is for UI replace
			if (skippedTypes.contains(errType)) {
				errorMsg = cleanseMessage(errorMsg, errType);
			} else {
				//Default to Friendly message
				errorMsg = SYSMSG;
			}
		} else {
			errorMsg = SYSMSG;
		}
		for (SObject sobj : lSobjects) {
			String sInputStream = String.format('{0} {1}\n{2}', new LIST<String> {
				String.valueOf(err.getCause()),
				String.valueOf(err.getLineNumber()),
				String.valueOf(sobj)
			});
			LogEvent__e nLog = new LogEvent__e();
			nLog.CurrentUser__c = UserInfo.getUserId();
			nLog.Stack__c = getStack();
			nLog.Input__c = sInputStream;
			nLog.Message__c = String.valueOf(err.getMessage());
			nLog.Type__c = String.valueOf(err.getTypeName());
			nLog.Priority__c = 'ERROR';
			//dont log if type is in the list
			if (!skippedTypes.contains(errType) || System.isBatch() || System.isScheduled() || System.isFuture()) {
				listLogs.add(nLog);
			}
			//append error on sobject
			sobj.addError(errorMsg);
		}
		if (!listLogs.isEmpty()) {
			QueueLogs(listLogs);
		}
	}
	/**
	 * Log Commit Error Records
	 * @param commitRecords List of CommitRecords
	 */
	public static void logCommitRecords(GLBL_BaseClass.CommitRecord[] commitRecords) {
		logCommitRecords(commitRecords, null);
	}
	/**
	 * Log Commit Error Records
	 * @param commitRecords  CommitError Records
	 * @param triggerRecords Trigger Records
	 */
	public static void logCommitRecords(GLBL_BaseClass.CommitRecord[] commitRecords, List<SObject> triggerRecords) {
		List<LogEvent__e> listLogs = new List<LogEvent__e>();
		if (commitRecords != null) {
			for (GLBL_BaseClass.CommitRecord oerror : commitRecords) {
				if (oerror.getIsSuccess() == false) {
					LogEvent__e nLog = new LogEvent__e();
					nLog.CurrentUser__c = UserInfo.getUserId();
					nLog.Stack__c = getStack();
					nLog.Input__c = JSON.serialize(oerror.record);
					nLog.Message__c = String.valueOf(oerror.errorsMsg);
					nLog.Type__c = oerror.getErrorType();
					nLog.Priority__c = 'ERROR';
					//dont log if type is in the list
					//Allow from Batch, Schedule and Future
					if (!skippedTypes.contains(nLog.Type__c) || System.isBatch() || System.isScheduled() || System.isFuture()) {
						listLogs.add(nLog);
					}
				}
			}

			if (!listLogs.isEmpty()) {
				QueueLogs(listLogs);
			}
			//Add error on Trigger Objects is preventing database commit
			if (triggerRecords != null && !commitRecords.isEmpty()) {
				for (SObject sobj : triggerRecords) {
					String[] errArray = commitRecords[0].errorsMsg;
					Integer lengthArr = errArray.size() - 1;
					String sMsg = errArray.get(lengthArr);
					sobj.addError(sMsg);
				}
			}
		}
	}
	/**
	 * commit changes to LogEvent__e object
	 */
	@TestVisible
	static void QueueLogs(List<LogEvent__e> nLogs) {
		if (nLogs != null) {
			if (!nLogs.isEmpty()) {
				//Moved to publish platform events and perform after insert DML
				EventBus.publish(nLogs);
			}
		}
	}
	static void QueueLogs(LogEvent__e niLog) {
		if (niLog != null) {
			QueueLogs(new List<LogEvent__e> {niLog});
		}
	}
	/**
	 * Retrieves calling stack
	 * @return Stack instance
	 */
	@TestVisible
	static String getStack() {
		String[] stackException = new DmlException().getStackTraceString().split('\n');
		String callingStack = stackException[2].substringBefore(':').substringBeforeLast(':');
		return callingStack;
	}
	@TestVisible
	static String getDebugStack() {
		String[] stackException = new DmlException().getStackTraceString().split('\n');
		String callingStack = stackException[2].substringBefore(', column');
		return callingStack;
	}
	@TestVisible
	static String cleanseMessage(String errorMsg, String errType) {
		String subStr = String.format('{0}, ', new LIST<String> {errType});
		if (String.isNotBlank(errorMsg) && String.isNotBlank(errType)) {
			if (errorMsg.contains(']: [')) {
				errorMsg = errorMsg.substringBetween(subStr, ']: [');
				if (errorMsg.contains('[')) {
					errorMsg = errorMsg.replace('[', '');
				}
			}
		}
		return errorMsg;
	}
}