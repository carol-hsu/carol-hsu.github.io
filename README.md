# My Personal Website

Trying to develop/study some frontend works with [Hugo](https://gohugo.io).
I have gone through following studies, and set/configure them to fit my requirements (my expectations of how the website should looks like).

0. Hugo installation and basic command lines 
1. Github workflow 
2. Choose a theme as the style template, and adapt it in this repo
3. Setup the configuration file of the website `./hugo.toml`.
    
    The most important thing is that, in this file, we need to define the theme we used.

4. Understand the directories and files, and their relationships with `./hugo.toml`:
- `assets` and `layouts`: for the detail settings of the theme. Here is where we should change/overwrite the settings of the theme. Or, the website will be deployed with the configurations in `./theme/THEME_NAME` 
- `content`: 
    - `_index.md`
    - `./post`    
- `static`: static files like icons and images
    - `./image`
5. Update content 

### Markdown syntax used in the content

This website uses the theme [jane](https://github.com/xianmin/hugo-theme-jane). 
There are some useful syntaxes that supported by original mardown application and jane.

- Word style in the sentense

```
 **bold word** / *italic word* / `in-code word`
```

- Hyperlink

```
[The displayed word of link](https://LINK_URL)
```

- Footnote

```
The word[^fn-uid] you want to add footnote.

[^fn-uid]: More description/citation will show on the bottom of the article.
```

- Expand message

```
{{< expand "This title will show up, not be extended" >}}
Here comes some content..
{{< /expand >}}
```

More usages and methods are introduced in the [official documentations](https://www.xianmin.org/hugo-theme-jane/post/).

