import discord
from discord.ext import commands
import asyncio
import random
import json

intents = discord.Intents.all()
bot = commands.Bot(command_prefix='!', intents=intents)

class LifeSimulator(commands.Cog):
    def __init__(self, bot):
        self.bot = bot
        self.money = 0
        self.gender = None
        self.perks = []
        
      #I am definning these values twice ^ \/
      
        with open("user_data.json", "r") as f:
            user_data = json.load(f)
            self.money = user_data["money"]
            self.gender = user_data["gender"]
            self.perks = user_data["perks"]

    @commands.command()
    async def begin(self, ctx):
        if self.gender is not None or len(self.perks) > 0:
            await ctx.send("You have already selected your gender and perks.")
            return

        await ctx.send("What are your three perks? (Please separate them with commas.)")

        def check(message):
            return message.author == ctx.author and len(message.content.split(",")) == 3 and all(perk.strip().capitalize() in ["Strength", "Smarts", "Looks", "Athleticism", "Success", "Luck"] for perk in message.content.split(","))

        message = await bot.wait_for("message", check=check)

        self.perks = [perk.strip().capitalize() for perk in message.content.split(",")]

        # Update the data in the JSON file
        with open("user_data.json", "w") as f:
            user_data = {
                "money": self.money,
                "gender": self.gender,
                "perks": self.perks
            }
            json.dump(user_data, f)

        await ctx.send("What is your gender? (Please type boy or girl)")

        def check_gender(message):
            return message.author == ctx.author and message.content.lower() in ["boy", "girl"]

        message = await bot.wait_for("message", check=check_gender)

        if message.content.lower() == "boy":
            self.gender = "Boy"
        else:
            self.gender = "Girl"

        # Update the data in the JSON file
        with open("user_data.json", "w") as f:
            user_data = {
                "money": self.money,
                "gender": self.gender,
                "perks": self.perks
            }
            json.dump(user_data, f)

        await ctx.send("You have selected your gender and perks.")

    @commands.command()
    async def perks(self, ctx):
        await ctx.send(f"Your perks are: {', '.join(self.perks)}")

    @commands.command()
    async def gender(self, ctx):
        with open("user_data.json", "r") as f:
            lines = f.readlines()

        gender_line = [line for line in lines if line.startswith("Gender:")][0]
        gender = gender_line.split(":")[1].strip()

        self.gender = gender

        await ctx.send(f"Your gender is: {gender}")

    @commands.command()
    async def work(self, ctx):
        money_earned = random.randint(10, 100)
        self.money += money_earned
        await ctx.send(f"You earned ${money_earned}! You now have ${self.money}.")

    @commands.command()
    async def bank(self, ctx):
        await ctx.send(f"You have ${self.money} in your bank account.")

async def setup():
    await bot.add_cog(LifeSimulator(bot))

asyncio.run(setup())
bot.run('MTA4OTYyNDUxMjI0MjM4ODk5Mg.Gda6E4.L_ZL6c4scsN8_aZa6qiBgpttVEYA27M9koMra8')
