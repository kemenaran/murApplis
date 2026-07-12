This repository is an attempt at solving a small programming challenge using [literate programming](https://en.wikipedia.org/wiki/Literate_programming).

## The challenge

First proposed by a defunct IT services company ([original source, in french](https://web.archive.org/web/20121129225904/http://applidium.com/jobs/challenges/#random)):

> ### Challenge #3 – Apps wall
>
> In our offices, we display a mosaic of the most downloaded apps from the App Store on a screen. To prevent the TV's pixels from burning out, it's important to shuffle the icons regularly. Could you write a program that takes a list of apps as input and outputs that same list, randomly shuffled, while ensuring that every app has changed places?
>
> Each application would be represented by an integer, both as input and output:
>
> ```shell
> echo "1,3,2,5,4" | ./murApplis => "3,1,4,5,2"
> ```

## Literate programming

The solution can be viewed as a web page here: https://kemenaran.github.io/murApplis/

> [!NOTE]
> The literate programming source (`murApplis_tests.rb`) and the minimal binary that answers the challenge (`murApplis`) are also included, but are less interesting than the complete web page.
