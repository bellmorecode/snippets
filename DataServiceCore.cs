public abstract class DataServiceCore : IDisposable
{
    SqlConnection? cn;
    public void Connect(string cs)
    {
        if (cn == null)
        {
            cn = new SqlConnection(cs); cn.Open();
        }
    }

    protected SqlConnection ActiveConnection
    {
        get
        {
            if (cn == null || cn.State != ConnectionState.Open)
            {
                throw new InvalidOperationException("You need to call 'Connect' first to open a connection.");
            }
            return cn;
        }
    }

    public DataTable GetData(string query)
    {
        var table = new DataTable();

        if (cn == null || cn.State != ConnectionState.Open)
        {
            throw new InvalidOperationException("You need to call 'Connect' first to open a connection.");
        }

        try
        {
            if (cn != null && query != null)
            {
                using (var cmd = cn.CreateCommand())
                {
                    cmd.CommandText = query;
                    using (var adapter = new SqlDataAdapter(cmd))
                    {
                        adapter.Fill(table);
                    }
                }
            }
        }
        catch(Exception ex)
        {
            Trace.TraceError($"{ex}");
            throw;
        }

        return table;
    }

    public TResult ExecuteScalar<TResult>(string query)
    {
        if (cn == null) throw new InvalidOperationException("Connect to database before executing statements");
        using (var cmd = cn.CreateCommand())
        {
            cmd.CommandText = query;
            return (TResult)cmd.ExecuteScalar();
        }
    }

    public int ExecuteNonQuery(string query)
    {
        if (cn == null) throw new InvalidOperationException("Connect to database before executing statements");
        using (var cmd = cn.CreateCommand())
        {
            cmd.CommandText = query;
            return cmd.ExecuteNonQuery();
        }
    }

    public void Dispose()
    {
        if (cn != null)
        {
            try
            {
                using (cn) { cn.Close(); }
                cn = null;
            }
            catch (Exception ex)
            {
                Trace.TraceError($"Error on DataServiceCore dispose: {ex}");
            }
        }
    }
}
