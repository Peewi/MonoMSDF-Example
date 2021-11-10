using FontExtension;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;
using System.Diagnostics;

namespace MonoMSDF_Example
{
	/// <summary>
	/// This is the main type for your game.
	/// </summary>
	public class Game1 : Game
	{
		private GraphicsDeviceManager graphics;
		private TextRenderer mainTextRenderer;
		private TextRenderer textRenderer3D;
		private TextRenderer segoescriptRenderer;
		FieldFont mainFont;
		FieldFont segoescriptFont;
		Stopwatch frameWatch;
		long frameTime = 0;
		long frameTicks = 0;
		float scale = 1;
		int scrolled = 0;

		public Game1()
		{
			graphics = new GraphicsDeviceManager(this)
			{
				PreferredBackBufferWidth = 1280,
				PreferredBackBufferHeight = 720,
				SynchronizeWithVerticalRetrace = false,
				GraphicsProfile = GraphicsProfile.HiDef
			};
			IsFixedTimeStep = false;
			Window.AllowUserResizing = true;
			IsMouseVisible = true;
			Content.RootDirectory = "Content";
			graphics.PreparingDeviceSettings += (sender, e) =>
			{
				int w = e.GraphicsDeviceInformation.PresentationParameters.BackBufferWidth;
				int h = e.GraphicsDeviceInformation.PresentationParameters.BackBufferHeight;
				mainTextRenderer?.SetOrtographicProjection(w, h);
				segoescriptRenderer?.SetOrtographicProjection(w, h);
			};
		}

		protected override void Initialize()
		{
			base.Initialize();
			frameWatch = new Stopwatch();
		}

		protected override void LoadContent()
		{
			var effect = Content.Load<Effect>("FieldFontEffect");
			mainFont = Content.Load<FieldFont>("arial");
			segoescriptFont = Content.Load<FieldFont>("segoescript");

			mainTextRenderer = new TextRenderer(effect, mainFont, GraphicsDevice);
			textRenderer3D = new TextRenderer(effect, mainFont, GraphicsDevice);
			segoescriptRenderer = new TextRenderer(effect, segoescriptFont, GraphicsDevice);
			mainTextRenderer.SetOrtographicProjection(1280, 720);
			segoescriptRenderer.SetOrtographicProjection(1280, 720);
			
			GraphicsDevice.BlendState = BlendState.AlphaBlend;
			GraphicsDevice.DepthStencilState = DepthStencilState.None;
			GraphicsDevice.RasterizerState = RasterizerState.CullNone;
		}

		protected override void Update(GameTime gameTime)
		{
			if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed
				|| Keyboard.GetState().IsKeyDown(Keys.Escape))
				Exit();

			int scroll = Mouse.GetState().ScrollWheelValue;
			if (scroll > scrolled)
			{
				scale += 0.1f;
			}
			else if (scroll < scrolled)
			{
				scale -= 0.1f;
			}
			scrolled = scroll;
			base.Update(gameTime);
		}

		protected override void Draw(GameTime gameTime)
		{
			frameWatch.Restart();
			float totalTime = (float)gameTime.TotalGameTime.TotalSeconds;
			GraphicsDevice.Clear(Color.CornflowerBlue);
			// Text layouted in 3D
			var viewport = GraphicsDevice.Viewport;
			var world = Matrix.CreateScale(0.01f) * Matrix.Identity;
			var view = Matrix.CreateLookAt(Vector3.Backward, Vector3.Forward, Vector3.Up);
			var projection = Matrix.CreatePerspectiveFieldOfView(
				MathHelper.PiOver2,
				viewport.Width / (float)viewport.Height,
				0.01f,
				1000.0f);

			var wvp = world * view * projection;
			textRenderer3D.ResetLayout();
			textRenderer3D.LayoutText("→~!435&^%$", Vector2.Zero, Color.White, 32, MathF.Sin(totalTime) * 10);
			textRenderer3D.RenderText(wvp);

			world = Matrix.CreateScale(0.01f) * Matrix.CreateRotationY(totalTime) * Matrix.CreateRotationZ(MathHelper.PiOver4);
			view = Matrix.CreateLookAt(Vector3.Backward, Vector3.Forward, Vector3.Up);
			projection = Matrix.CreatePerspectiveFieldOfView(
				MathHelper.PiOver2,
				viewport.Width / (float)viewport.Height,
				0.01f,
				1000.0f);

			wvp = world * view * projection;
			textRenderer3D.ResetLayout();
			textRenderer3D.LayoutText("To Infinity And Beyond!", Vector2.Zero, Color.Pink, Color.Black, 32);
			textRenderer3D.RenderText(wvp);
			// Text layouted in 2D
			mainTextRenderer.ResetLayout();
			mainTextRenderer.LayoutText("Look at this text!", new Vector2(0, 0), Color.Yellow, Color.Black, 32);
			mainTextRenderer.LayoutText("Text can be big.", new Vector2(0, 32), Color.Red, Color.Black, 64f);
			mainTextRenderer.LayoutText("Text can even be small.", new Vector2(0, 96), Color.White, 16f);
			mainTextRenderer.LayoutText("It's a piñata", new Vector2(0, 112), Color.Gold, Color.Black, 32);
			mainTextRenderer.LayoutText("Text with kerning:", new Vector2(0, 144), Color.Gold, Color.Black, 32);
			mainTextRenderer.LayoutText("AWAY", new Vector2(310, 144), Color.Gold, Color.Black, 32);
			mainTextRenderer.EnableKerning = false;
			mainTextRenderer.LayoutText("Text without kerning:", new Vector2(0, 172), Color.Red, Color.Black, 32, 20);
			mainTextRenderer.LayoutText("AWAY", new Vector2(310, 172), Color.Red, Color.Black, 32, 20);
			mainTextRenderer.EnableKerning = true;
			mainTextRenderer.LayoutText($"LESS BIG\nIN BACK", new Vector2(100, 300), Color.Blue, Color.Orange, 32 * 2, 0.1f);
			mainTextRenderer.LayoutText($"Frame time: 0{frameTicks} ticks\nFrame time: {frameTime}ms", new Vector2(0, 720 - 265), Color.Gold, Color.Black, 64);
			mainTextRenderer.LayoutText($"Running for {gameTime.TotalGameTime.TotalSeconds} seconds", new Vector2(0, 720 - 40), Color.Gold, Color.Black, 32);
			mainTextRenderer.LayoutText($"REALLY BIG\nIN FRONT", new Vector2(0, 200), Color.Transparent, Color.Gold, 32 * 5);
			mainTextRenderer.RenderStrokedText();

			segoescriptRenderer.ResetLayout();
			string cursorText = $"This is rotated.\nAnd a different font.";
			Vector2 ctMeasure = segoescriptFont.MeasureString(cursorText) * scale * 32;
			segoescriptRenderer.LayoutText(cursorText, Mouse.GetState().Position.ToVector2() - ctMeasure / 2, Color.Black, Color.White, scale * 32, totalTime, ctMeasure / 2);
			segoescriptRenderer.RenderStroke();
			segoescriptRenderer.RenderText();
			// stopwatch
			frameTicks = frameWatch.ElapsedTicks;
			frameTime = frameWatch.ElapsedMilliseconds;
			frameWatch.Stop();
		}
	}
}
