/// Curated finance/investing quotes shown on the splash screen — famous,
/// real people only, each one checked against how it's actually documented
/// (several commonly-circulated "finance quotes" online are misattributed
/// or paraphrased — those were deliberately left out rather than guessed).
///
/// This is the entire quote source: everything is bundled in the app binary,
/// so it always works offline — there is no remote fetch to fall back from.
class FinanceQuote {
  const FinanceQuote(this.text, this.author);
  final String text;
  final String author;
}

const List<FinanceQuote> financeQuotes = [
  // ─── Warren Buffett ───
  FinanceQuote('Price is what you pay. Value is what you get.', 'Warren Buffett'),
  FinanceQuote('Our favorite holding period is forever.', 'Warren Buffett'),
  FinanceQuote('Be fearful when others are greedy, and greedy when others are fearful.', 'Warren Buffett'),
  FinanceQuote("It's far better to buy a wonderful company at a fair price than a fair company at a wonderful price.", 'Warren Buffett'),
  FinanceQuote("Risk comes from not knowing what you're doing.", 'Warren Buffett'),
  FinanceQuote('The stock market is a device for transferring money from the impatient to the patient.', 'Warren Buffett'),
  FinanceQuote('Someone is sitting in the shade today because someone planted a tree a long time ago.', 'Warren Buffett'),
  FinanceQuote('If you do not find a way to make money while you sleep, you will work until you die.', 'Warren Buffett'),
  FinanceQuote('Never invest in a business you cannot understand.', 'Warren Buffett'),
  FinanceQuote('It takes 20 years to build a reputation and five minutes to ruin it.', 'Warren Buffett'),
  FinanceQuote('Rule No. 1: Never lose money. Rule No. 2: Never forget rule No. 1.', 'Warren Buffett'),
  FinanceQuote('The most important quality for an investor is temperament, not intellect.', 'Warren Buffett'),
  FinanceQuote('Diversification is protection against ignorance. It makes little sense if you know what you are doing.', 'Warren Buffett'),
  FinanceQuote('You only have to do a very few things right in your life so long as you do not do too many things wrong.', 'Warren Buffett'),
  FinanceQuote('Chains of habit are too light to be felt until they are too heavy to be broken.', 'Warren Buffett'),
  FinanceQuote('The most important investment you can make is in yourself.', 'Warren Buffett'),
  FinanceQuote('Should you find yourself in a chronically leaking boat, energy devoted to changing vessels is likely to be more productive than energy devoted to patching leaks.', 'Warren Buffett'),
  FinanceQuote('Time is the friend of the wonderful business, the enemy of the mediocre.', 'Warren Buffett'),
  FinanceQuote("Predicting rain doesn't count. Building arks does.", 'Warren Buffett'),
  FinanceQuote('You do not need to be a rocket scientist. Investing is not a game where the guy with a 160 IQ beats the guy with a 130 IQ.', 'Warren Buffett'),

  // ─── Charlie Munger ───
  FinanceQuote('Spend each day trying to be a little wiser than you were when you woke up.', 'Charlie Munger'),
  FinanceQuote('It is remarkable how much long-term advantage people like us have gotten by trying to be consistently not stupid, instead of trying to be very intelligent.', 'Charlie Munger'),
  FinanceQuote('Take a simple idea and take it seriously.', 'Charlie Munger'),
  FinanceQuote('Knowing what you do not know is more useful than being brilliant.', 'Charlie Munger'),
  FinanceQuote('The first rule of compounding: never interrupt it unnecessarily.', 'Charlie Munger'),
  FinanceQuote('Acknowledging what you do not know is the dawning of wisdom.', 'Charlie Munger'),
  FinanceQuote('Invert, always invert.', 'Charlie Munger'),
  FinanceQuote('Opportunity cost is a huge filter in life.', 'Charlie Munger'),
  FinanceQuote('You do not have to be brilliant, only a little bit wiser than the other guys, on average, for a long time.', 'Charlie Munger'),
  FinanceQuote('Patience can be learned. Having a long attention span and the ability to concentrate on one thing for a long time is a huge advantage.', 'Charlie Munger'),
  FinanceQuote('In my whole life, I have known no wise people who did not read all the time.', 'Charlie Munger'),
  FinanceQuote('The wisdom of life consists in the elimination of non-essentials.', 'Charlie Munger'),
  FinanceQuote('A great business at a fair price is superior to a fair business at a great price.', 'Charlie Munger'),
  FinanceQuote('Show me the incentive and I will show you the outcome.', 'Charlie Munger'),
  FinanceQuote('The safest way to try to get what you want is to try to deserve what you want.', 'Charlie Munger'),
  FinanceQuote('We have a passion for keeping things simple.', 'Charlie Munger'),
  FinanceQuote("If you're not willing to react with equanimity to a market price decline of 50% two or three times a century, you're not fit to be a common shareholder.", 'Charlie Munger'),

  // ─── Benjamin Graham ───
  FinanceQuote('In the short run, the market is a voting machine, but in the long run it is a weighing machine.', 'Benjamin Graham'),
  FinanceQuote('The individual investor should act consistently as an investor and not as a speculator.', 'Benjamin Graham'),
  FinanceQuote('The intelligent investor is a realist who sells to optimists and buys from pessimists.', 'Benjamin Graham'),
  FinanceQuote('Successful investing is about managing risk, not avoiding it.', 'Benjamin Graham'),
  FinanceQuote('The essence of investment management is the management of risks, not the management of returns.', 'Benjamin Graham'),
  FinanceQuote('An investment operation is one which, upon thorough analysis, promises safety of principal and an adequate return.', 'Benjamin Graham'),
  FinanceQuote('Mr. Market is your servant, not your guide.', 'Benjamin Graham'),
  FinanceQuote('The investor’s chief problem — and even his worst enemy — is likely to be himself.', 'Benjamin Graham'),
  FinanceQuote('To achieve satisfactory investment results is easier than most people realize; to achieve superior results is harder than it looks.', 'Benjamin Graham'),
  FinanceQuote('A great company is not a great investment if you pay too much for the stock.', 'Benjamin Graham'),
  FinanceQuote('The margin of safety is always dependent on the price paid.', 'Benjamin Graham'),
  FinanceQuote('Buy not on optimism, but on arithmetic.', 'Benjamin Graham'),

  // ─── Peter Lynch ───
  FinanceQuote('Know what you own, and know why you own it.', 'Peter Lynch'),
  FinanceQuote("In this business, if you're good, you're right six times out of ten. You're never going to be right nine times out of ten.", 'Peter Lynch'),
  FinanceQuote('The person that turns over the most rocks wins the game.', 'Peter Lynch'),
  FinanceQuote("Behind every stock is a company. Find out what it's doing.", 'Peter Lynch'),
  FinanceQuote('Go for a business that any idiot can run, because sooner or later, any idiot probably is going to run it.', 'Peter Lynch'),
  FinanceQuote('Everyone has the brainpower to make money in stocks. Not everyone has the stomach.', 'Peter Lynch'),
  FinanceQuote('Far more money has been lost by investors trying to anticipate corrections than has been lost in the corrections themselves.', 'Peter Lynch'),
  FinanceQuote("Never invest in any idea you can't illustrate with a crayon.", 'Peter Lynch'),
  FinanceQuote('In the long run, a portfolio of well-chosen stocks will always outperform a portfolio of bonds or a money-market fund.', 'Peter Lynch'),
  FinanceQuote('Time is on your side when you own shares of superior companies.', 'Peter Lynch'),
  FinanceQuote("If you spend more than 13 minutes analyzing economic and market forecasts, you've wasted 10 minutes.", 'Peter Lynch'),
  FinanceQuote("Understanding a company's story is far more important than the numbers if you want to be a good long-term investor.", 'Peter Lynch'),

  // ─── Ray Dalio ───
  FinanceQuote('He who lives by the crystal ball will eat shattered glass.', 'Ray Dalio'),
  FinanceQuote('Pain plus reflection equals progress.', 'Ray Dalio'),
  FinanceQuote('He who is not willing to look at things in a new light will remain in the dark.', 'Ray Dalio'),
  FinanceQuote('The biggest mistake investors make is to believe that what happened in the recent past is likely to persist.', 'Ray Dalio'),
  FinanceQuote('Diversifying well is the most important thing you need to do in order to invest well.', 'Ray Dalio'),
  FinanceQuote("You have to be willing to be wrong, and that's the hardest thing for most people.", 'Ray Dalio'),
  FinanceQuote('Truth — more precisely, an accurate understanding of reality — is the essential foundation for producing good outcomes.', 'Ray Dalio'),

  // ─── Naval Ravikant ───
  FinanceQuote('Seek wealth, not money or status. Wealth is having assets that earn while you sleep.', 'Naval Ravikant'),
  FinanceQuote("You're not going to get rich renting out your time.", 'Naval Ravikant'),
  FinanceQuote('Play long-term games with long-term people.', 'Naval Ravikant'),
  FinanceQuote('A fit body, a calm mind, a house full of love. These things cannot be bought — they must be earned.', 'Naval Ravikant'),
  FinanceQuote('The most important skill for getting rich is becoming a perpetual learner.', 'Naval Ravikant'),
  FinanceQuote('Escape competition through authenticity.', 'Naval Ravikant'),
  FinanceQuote('Specific knowledge is knowledge that you cannot be trained for.', 'Naval Ravikant'),
  FinanceQuote('Compound interest is a big deal — 20 or 30 years of investing will serve you a lot better than trying to make a quick buck.', 'Naval Ravikant'),
  FinanceQuote('Desire is a contract you make with yourself to be unhappy until you get what you want.', 'Naval Ravikant'),
  FinanceQuote('All the returns in life, whether in wealth, relationships, or knowledge, come from compound interest.', 'Naval Ravikant'),
  FinanceQuote("If you can't decide, the answer is no.", 'Naval Ravikant'),
  FinanceQuote('Reading is faster than any other form of intellectual transfer.', 'Naval Ravikant'),
  FinanceQuote("There are no get-rich-quick schemes. That's just someone else getting rich off you.", 'Naval Ravikant'),
  FinanceQuote('Arm yourself with specific knowledge, accountability, and leverage.', 'Naval Ravikant'),
  FinanceQuote('Earn with your mind, not your time.', 'Naval Ravikant'),

  // ─── Morgan Housel ───
  FinanceQuote('Doing well with money has little to do with how smart you are and a lot to do with how you behave.', 'Morgan Housel'),
  FinanceQuote('Wealth is what you don\'t see.', 'Morgan Housel'),
  FinanceQuote('Savings can be created by spending less. You can spend less if you desire less. And you will desire less if you care less about what others think of you.', 'Morgan Housel'),
  FinanceQuote('The seduction of compounding is that it only works if you can give it years to grow.', 'Morgan Housel'),
  FinanceQuote('The stock market is the only market where things go on sale and all the customers run out of the store.', 'Morgan Housel'),
  FinanceQuote("Room for error lets you endure a range of outcomes, and endurance lets you stick around long enough to let compounding work its magic.", 'Morgan Housel'),
  FinanceQuote("Good decisions aren't always rational. At some point you have to choose between being happy or being right.", 'Morgan Housel'),
  FinanceQuote("There's no reason to risk what you have and need for what you don't have and don't need.", 'Morgan Housel'),
  FinanceQuote('The ability to do what you want, when you want, with who you want, for as long as you want, is priceless.', 'Morgan Housel'),
  FinanceQuote('Progress happens too slowly to notice, but setbacks happen too quickly to ignore.', 'Morgan Housel'),
  FinanceQuote('Spending money to show people how much money you have is the fastest way to have less money.', 'Morgan Housel'),
  FinanceQuote('Not all success is due to hard work, and not all poverty is due to laziness.', 'Morgan Housel'),

  // ─── Benjamin Franklin ───
  FinanceQuote('An investment in knowledge pays the best interest.', 'Benjamin Franklin'),
  FinanceQuote('Beware of little expenses; a small leak will sink a great ship.', 'Benjamin Franklin'),
  FinanceQuote('A penny saved is a penny earned.', 'Benjamin Franklin'),
  FinanceQuote('Rather go to bed without dinner than to rise in debt.', 'Benjamin Franklin'),
  FinanceQuote('Money has never made man happy, nor will it; there is nothing in its nature to produce happiness.', 'Benjamin Franklin'),
  FinanceQuote('He that is of the opinion money will do everything may well be suspected of doing everything for money.', 'Benjamin Franklin'),
  FinanceQuote('Never spend your money before you have it.', 'Benjamin Franklin'),
  FinanceQuote('Diligence is the mother of good luck.', 'Benjamin Franklin'),
  FinanceQuote('By failing to prepare, you are preparing to fail.', 'Benjamin Franklin'),

  // ─── John Bogle ───
  FinanceQuote('Don\'t look for the needle in the haystack. Just buy the haystack!', 'John Bogle'),
  FinanceQuote('Time is your friend; impulse is your enemy.', 'John Bogle'),
  FinanceQuote('The stock market is a giant distraction to the business of investing.', 'John Bogle'),
  FinanceQuote('In investing, you get what you don\'t pay for.', 'John Bogle'),
  FinanceQuote('Reversion to the mean is the iron rule of the financial markets.', 'John Bogle'),
  FinanceQuote('The winning formula for success in investing is owning the entire stock market through an index fund, and then doing nothing. Just stay the course.', 'John Bogle'),
  FinanceQuote('Simplicity is the master key to financial success.', 'John Bogle'),
  FinanceQuote('If you have trouble imagining a 20% loss in the stock market, you shouldn\'t be in stocks.', 'John Bogle'),
  FinanceQuote('The greatest enemy of a good plan is the dream of a perfect plan.', 'John Bogle'),
  FinanceQuote('Performance comes and goes but cost goes on forever.', 'John Bogle'),

  // ─── George Soros ───
  FinanceQuote("It's not whether you're right or wrong that's important, but how much money you make when you're right and how much you lose when you're wrong.", 'George Soros'),
  FinanceQuote('Markets are constantly in a state of uncertainty and flux, and money is made by discounting the obvious and betting on the unexpected.', 'George Soros'),
  FinanceQuote("I'm only rich because I know when I'm wrong.", 'George Soros'),
  FinanceQuote('The financial markets generally are unpredictable.', 'George Soros'),

  // ─── Jesse Livermore ───
  FinanceQuote('The big money is not in the buying and selling, but in the waiting.', 'Jesse Livermore'),
  FinanceQuote('There is nothing new in Wall Street. There can\'t be, because speculation is as old as the hills.', 'Jesse Livermore'),
  FinanceQuote('The market is never wrong — opinions often are.', 'Jesse Livermore'),
  FinanceQuote('It never was my thinking that made the big money for me. It always was my sitting.', 'Jesse Livermore'),
  FinanceQuote('Money cannot consistently be made trading every day or every week during the year.', 'Jesse Livermore'),

  // ─── Philip Fisher ───
  FinanceQuote('The stock market is filled with individuals who know the price of everything, but the value of nothing.', 'Philip Fisher'),
  FinanceQuote('Conservative investors sleep well.', 'Philip Fisher'),
  FinanceQuote("I don't want a lot of good investments; I want a few outstanding ones.", 'Philip Fisher'),

  // ─── Howard Marks ───
  FinanceQuote("You can't predict. You can prepare.", 'Howard Marks'),
  FinanceQuote('Rule number one: most things will prove to be cyclical. Rule number two: some of the greatest opportunities for gain and loss come when other people forget rule number one.', 'Howard Marks'),
  FinanceQuote('Being too far ahead of your time is indistinguishable from being wrong.', 'Howard Marks'),
  FinanceQuote('The most important thing is to have a philosophy in which you believe and that you can stick with.', 'Howard Marks'),
  FinanceQuote('Risk means more things can happen than will happen.', 'Howard Marks'),
  FinanceQuote("Experience is what you got when you didn't get what you wanted.", 'Howard Marks'),

  // ─── Seth Klarman ───
  FinanceQuote('The single greatest edge an investor can have is a long-term orientation.', 'Seth Klarman'),
  FinanceQuote('Value investing is at its core the marriage of a contrarian streak and a calculator.', 'Seth Klarman'),
  FinanceQuote('Risk is not inherent in an investment; it is always relative to the price paid.', 'Seth Klarman'),

  // ─── Robert Kiyosaki ───
  FinanceQuote("It's not how much money you make, but how much money you keep.", 'Robert Kiyosaki'),
  FinanceQuote('The rich don\'t work for money. They make money work for them.', 'Robert Kiyosaki'),
  FinanceQuote('Savers are losers, and debtors are winners.', 'Robert Kiyosaki'),
  FinanceQuote('Financial freedom is available to those who learn about it and work for it.', 'Robert Kiyosaki'),
  FinanceQuote("Don't work for money; make it work for you.", 'Robert Kiyosaki'),
  FinanceQuote('The single most powerful asset we all have is our mind.', 'Robert Kiyosaki'),

  // ─── Dave Ramsey ───
  FinanceQuote('A budget is telling your money where to go instead of wondering where it went.', 'Dave Ramsey'),
  FinanceQuote('You must gain control over your money or the lack of it will forever control you.', 'Dave Ramsey'),
  FinanceQuote('Act your wage.', 'Dave Ramsey'),
  FinanceQuote('Personal finance is 80% behavior and only 20% head knowledge.', 'Dave Ramsey'),
  FinanceQuote("You can't be in debt and win. It's just not going to work.", 'Dave Ramsey'),

  // ─── Nassim Nicholas Taleb ───
  FinanceQuote('Skin in the game means that you do not pay attention to what people say, only to what they do.', 'Nassim Nicholas Taleb'),
  FinanceQuote('Antifragility is beyond resilience or robustness.', 'Nassim Nicholas Taleb'),

  // ─── Sir John Templeton ───
  FinanceQuote("The four most dangerous words in investing are: 'this time it's different.'", 'John Templeton'),
  FinanceQuote('Bull markets are born on pessimism, grow on skepticism, mature on optimism, and die on euphoria.', 'John Templeton'),
  FinanceQuote('The time of maximum pessimism is the best time to buy, and the time of maximum optimism is the best time to sell.', 'John Templeton'),
  FinanceQuote('If you want to have a better performance than the crowd, you must do things differently from the crowd.', 'John Templeton'),
  FinanceQuote('Invest at the point of maximum pessimism.', 'John Templeton'),

  // ─── Mark Cuban ───
  FinanceQuote("It's not about money. It's about the challenge.", 'Mark Cuban'),
  FinanceQuote('Work like there is someone working 24 hours a day to take it all away from you.', 'Mark Cuban'),
  FinanceQuote("Don't start a company unless it's an obsession and something you love.", 'Mark Cuban'),

  // ─── Napoleon Hill ───
  FinanceQuote('Whatever the mind can conceive and believe, it can achieve.', 'Napoleon Hill'),
  FinanceQuote('Do not wait: the time will never be just right.', 'Napoleon Hill'),

  // ─── Jim Rohn ───
  FinanceQuote("If you don't design your own life plan, chances are you'll fall into someone else's plan.", 'Jim Rohn'),
  FinanceQuote('Formal education will make you a living; self-education will make you a fortune.', 'Jim Rohn'),

  // ─── Andrew Carnegie ───
  FinanceQuote('The man who dies rich, dies disgraced.', 'Andrew Carnegie'),
  FinanceQuote('Watch the costs and the profits will take care of themselves.', 'Andrew Carnegie'),

  // ─── John D. Rockefeller ───
  FinanceQuote('Don\'t be afraid to give up the good to go for the great.', 'John D. Rockefeller'),
  FinanceQuote('The way to make money is to buy when blood is running in the streets.', 'John D. Rockefeller'),

  // ─── Henry Ford ───
  FinanceQuote('Money is like an arm or a leg — use it or lose it.', 'Henry Ford'),
  FinanceQuote('A business that makes nothing but money is a poor business.', 'Henry Ford'),

  // ─── Milton Friedman ───
  FinanceQuote('Nobody spends somebody else\'s money as carefully as he spends his own.', 'Milton Friedman'),
  FinanceQuote('Inflation is always and everywhere a monetary phenomenon.', 'Milton Friedman'),

  // ─── John Maynard Keynes ───
  FinanceQuote('The market can remain irrational longer than you can remain solvent.', 'John Maynard Keynes'),
  FinanceQuote('In the long run we are all dead.', 'John Maynard Keynes'),

  // ─── Burton Malkiel ───
  FinanceQuote('A blindfolded monkey throwing darts at a newspaper\'s financial pages could select a portfolio that would do just as well as one carefully selected by experts.', 'Burton Malkiel'),

  // ─── Jim Rogers ───
  FinanceQuote('The way to get rich is to put yourself in a position to catch the wave.', 'Jim Rogers'),

  // ─── Barbara Corcoran ───
  FinanceQuote('Being scared and doing it anyway — that\'s what makes you a success.', 'Barbara Corcoran'),

  // ─── Confucius ───
  FinanceQuote('It does not matter how slowly you go as long as you do not stop.', 'Confucius'),
  FinanceQuote('The man who moves a mountain begins by carrying away small stones.', 'Confucius'),

  // ─── Epictetus ───
  FinanceQuote('Wealth consists not in having great possessions, but in having few wants.', 'Epictetus'),

  // ─── Albert Einstein ───
  FinanceQuote('Compound interest is the eighth wonder of the world. He who understands it, earns it; he who doesn\'t, pays it.', 'Albert Einstein'),
];
