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
	public static void throwAura(String name, String message, Integer code, String sType) {
		throw new AuraHandledException(new AuraExceptionData(name, message, code, sType).toJSON());
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
	public static void getLimits() {
		String sMsg = '!!@@##: \n';
		sMsg += getDebugStack() + '\n';
		sMsg += 'CPU Time:' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime() + '\n';
		sMsg += 'Heap Size:' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize() + '\n';
		sMsg += 'DML Rows:' + Limits.getDMLRows() + '/' + Limits.getLimitDMLRows() + '\n';
		sMsg += 'DML Statements:' + Limits.getDMLStatements() + '/' + Limits.getLimitDMLStatements() + '\n';
		sMsg += 'SOQL Queries:' + Limits.getQueries() + '/' + Limits.getLimitQueries() + '\n';
		sMsg += 'SOQL Rows:' + limits.getQueryRows() + '/' + Limits.getLimitQueryRows();
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
		String sParam1 = '';
		if (err.getCause() != null) {
			sParam1 += String.valueOf(err.getCause());
		}
		if (String.isNotBlank(err.getStackTraceString())) {
			sParam1 += String.valueOf(err.getStackTraceString());
		}
		String strObj = '';
		if (obj != null) {
			strObj = String.valueOf(obj);
		}
		String sInputStream = String.format('{0} {1}\n{2}', new LIST<String> {
			sParam1,
			String.valueOf(err.getLineNumber()),
			strObj
		});
		LogEvent__e nLog = new LogEvent__e();
		nLog.CurrentUser__c = UserInfo.getUserId();
		nLog.Stack__c = getStack();
		nLog.Input__c = sInputStream;
		nLog.Message__c = String.valueOf(err.getMessage());
		nLog.Type__c = String.valueOf(err.getTypeName());
		nLog.Priority__c = 'ERROR';
		//dont log if type is in the list
		if (!skippedTypes.contains(errType) || System.isBatch() || System.isScheduled() || System.isFuture() || System.isQueueable()) {
			QueueLogs(nLog);
		}
		//Since this is a validation rule reThrow message to user
		if (isValRuleError) {
			throw new LogUtilityException(cleanseValMessage(errorMsg));
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
		if (lSobjects != null) {
			for (SObject sobj : lSobjects) {
				String sParam1 = '';
				if (err.getCause() != null) {
					sParam1 += String.valueOf(err.getCause());
				}
				if (String.isNotBlank(err.getStackTraceString())) {
					sParam1 += String.valueOf(err.getStackTraceString());
				}
				String strObj = '';
				if (sobj != null) {
					strObj = JSON.serialize(sobj);
				}
				String sInputStream = String.format('{0} {1}\n{2}', new LIST<String> {
					sParam1,
					String.valueOf(err.getLineNumber()),
					strObj
				});
				LogEvent__e nLog = new LogEvent__e();
				nLog.CurrentUser__c = UserInfo.getUserId();
				nLog.Stack__c = getStack();
				nLog.Input__c = sInputStream;
				nLog.Message__c = String.valueOf(err.getMessage());
				nLog.Type__c = String.valueOf(err.getTypeName());
				nLog.Priority__c = 'ERROR';
				//dont log if type is in the list
				if (!skippedTypes.contains(errType) || System.isBatch() || System.isScheduled() || System.isFuture() || System.isQueueable()) {
					listLogs.add(nLog);
				}
				//append error on sobject
				sobj.addError(cleanseValMessage(errorMsg));
			}
			if (!listLogs.isEmpty()) {
				QueueLogs(listLogs);
			}
		}
	}
	/**
	 * Log Commit Error Records
	 * @param commitRecords List of CommitRecords
	 */
	public static void logCommitRecords(BaseClass.CommitRecord[] commitRecords) {
		logCommitRecords(commitRecords, null);
	}
	/**
	 * Log Commit Error Records
	 * @param commitRecords  CommitError Records
	 * @param triggerRecords Trigger Records
	 */
	public static void logCommitRecords(BaseClass.CommitRecord[] commitRecords, List<SObject> triggerRecords) {
		List<LogEvent__e> listLogs = new List<LogEvent__e>();
		if (commitRecords != null) {
			for (BaseClass.CommitRecord oerror : commitRecords) {
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
					if (!skippedTypes.contains(nLog.Type__c) || System.isBatch() || System.isScheduled() || System.isFuture() || System.isQueueable()) {
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
	 * Logs EmailResults
	 * @param emailResults EmailResults
	 */
	public static void logEmailErrors(Messaging.SendEmailResult[] emailResults) {
		List<LogEvent__e> listLogs = new List<LogEvent__e>();
		if (emailResults != null) {
			for (Messaging.SendEmailResult result : emailResults) {
				if (!result.isSuccess()) {
					for (Messaging.SendEmailError err : result.getErrors()) {
						LogEvent__e nLog = new LogEvent__e();
						nLog.CurrentUser__c = UserInfo.getUserId();
						nLog.Stack__c = getStack();
						nLog.Input__c = 'TargetObjectId=' + err.getTargetObjectId() + '\nFields=' + err.getFields();
						nLog.Message__c = String.valueOf(err.getMessage());
						nLog.Type__c = String.valueOf(err.getStatusCode());
						nLog.Priority__c = 'ERROR';
						listLogs.add(nLog);
					}
				}
			}

			if (!listLogs.isEmpty()) {
				QueueLogs(listLogs);
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
		//callingStack = stackException[2].substringBefore(':').substringBeforeLast(':');
		String callingStack = '';
		for (String str : stackException) {
			callingStack = str.substringBefore(':').substringBeforeLast(':');
			if (!str.containsIgnoreCase('Class.LogUtilityException')) {
				break;
			}
		}
		return callingStack;
	}
	@TestVisible
	static String getDebugStack() {
		String[] stackException = new DmlException().getStackTraceString().split('\n');
		String callingStack = '';
		for (String str : stackException) {
			callingStack = str.substringBefore(', column');
			if (!str.containsIgnoreCase('Class.LogUtilityException')) {
				break;
			}
		}
		return callingStack;
	}
	public static String cleanseMessage(String errorMsg, String errType) {
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
	public static String cleanseValMessage(String errorMsg) {
		String errType = StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION.name();
		String subStr = String.format('{0}, ', new LIST<String> {errType});
		if (String.isNotBlank(errorMsg) && String.isNotBlank(errType)) {
			if (errorMsg.contains(errType)) {
				errorMsg = errorMsg.substringBetween(subStr, ': [');
			}
		}
		return errorMsg;
	}
	// Wrapper class for my custom exception data to lightning component
	public class AuraExceptionData {
		public String name;
		public String message;
		public Integer code;
		public String variant;
		public String severity;

		public AuraExceptionData(String name, String message, Integer code, String typeMsg) {
			this.name = name;
			this.message = message;
			this.code = code;
			if (String.isBlank(this.name)) {
				this.name = 'System Exception';
			}
			// 'error', 'warning', 'success', or 'info'
			this.variant = typeMsg;
			if (code == 0) {
				this.name = 'Internal Server Error';
				this.message = SYSMSG;
				this.variant = 'error';
			}
			if (String.isNotBlank(this.variant)) {
				this.severity = this.variant;
				if (typeMsg == 'success') {
					this.severity = 'confirm';
				}
			}
		}
		public String toJSON() {
			return JSON.serialize(this);
		}
	}

}
