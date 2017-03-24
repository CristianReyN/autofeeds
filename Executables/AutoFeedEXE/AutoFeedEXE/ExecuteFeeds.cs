using System;
using System.Collections.Generic;
using System.Windows.Forms;

namespace AutoFeedEXE
{
  static class ExecuteFeeds
  {
    /// <summary>
    /// The main entry point for the application.
    /// </summary>
    [STAThread]
    static void Main()
    {
      Application.EnableVisualStyles();
      Application.SetCompatibleTextRenderingDefault(false);
      //Application.Run(new Form1());
    }
  }
}
