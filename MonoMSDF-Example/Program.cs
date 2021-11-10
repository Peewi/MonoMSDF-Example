using System;

namespace MonoMSDF_Example
{
	public static class Program
	{
		[STAThread]
		static void Main()
		{
			using (var game = new Game1())
				game.Run();
		}
	}
}
