-- {"id":1788,"ver":"1.0.0","libVer":"1.0.0","author":"TechnoJo4","dep":["NovelFull>=2.0.2"]}

return Require("NovelFull")("https://novel35.com", {
	id = 1788,
	name = "Novel35",
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/NovelFull.png",
	
	hasCloudFlare = true,
	meta_offset = 0,
	ajax_hot = "/search?type=hot",
	ajax_latest = "/search?type=latest",
	ajax_chapters = "/chapter-option",
	searchListSel = "list.list-truyen.col-xs-12",
	searchTitleSel = ".img-hover"
})
