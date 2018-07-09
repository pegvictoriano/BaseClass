/**
 * Interface for Trigger Base
 */
public interface ITriggerBase {
	
	void beforeInsert();
	void beforeUpdate();
	void beforeDelete();
	void afterInsert();
	void afterUpdate();
	void afterDelete();
	void afterUndelete();
	/**
	 * retrieves the Class Name
	 */
	String getHandlerName();
	/**
	 * retrieves the triggers context
	 */
	String getContext();
}