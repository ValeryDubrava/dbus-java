package org.freedesktop.dbus.viewer;

import java.util.ArrayList;
import java.util.List;

import javax.swing.table.AbstractTableModel;

class DBusTableModel extends AbstractTableModel
{
	private static final String INTROSPECTABLE = "introspectable?";

	private static final String OWNER = "owner";

	private static final String USER = "user";

	private static final String NAME = "name";

	final String[] columns = { NAME, USER, OWNER, INTROSPECTABLE };

	private List<DBusEntry> entries = new ArrayList<DBusEntry>();

	/** {@inheritDoc} */
	public int getRowCount()
	{
		return entries.size();
	}
	/** Add a row to the table model
	 * 
	 * @param entry The dbus entry to add
	 */
	public void add(DBusEntry entry)
	{
		entries.add(entry);
	}

	/** {@inheritDoc} */
	public int getColumnCount()
	{
		return columns.length;
	}

	/** {@inheritDoc} */
	@Override
	public String getColumnName(int column)
	{
		return columns[column];
	}
	
	/** Get a row of the table
	 * @param row The row index
	 * @return The table row
	 */
	public DBusEntry getEntry(int row)
	{
		return entries.get(row);
	}
	
	/** {@inheritDoc} */
	@Override
	public Class<?> getColumnClass(int columnIndex)
	{
		String columnName = getColumnName(columnIndex);
		if (columnName.equals(NAME))
		{
			return String.class;
		}
		else if (columnName.equals(USER))
		{
			return Object.class;
		}
		else if (columnName.equals(OWNER))
		{
			return String.class;
		}
		else if (columnName.equals(INTROSPECTABLE))
		{
			return Boolean.class;
		}
		return super.getColumnClass(columnIndex);
	}

	/** {@inheritDoc} */
	public Object getValueAt(int rowIndex, int columnIndex)
	{
		DBusEntry entry = getEntry(rowIndex);
		String columnName = getColumnName(columnIndex);
		if (columnName.equals(NAME))
		{
			return entry.getName();
		}
		else if (columnName.equals(USER))
		{
			return entry.getUser();
		}
		else if (columnName.equals(OWNER))
		{
			return entry.getOwner();
		}
		else if (columnName.equals(INTROSPECTABLE))
		{
			return entry.getIntrospectable() != null;
		}
		return null;
	}

}