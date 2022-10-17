-- {"id":1788,"ver":"1.0.4","libVer":"1.0.0","author":"TechnoJo4","dep":["Novel35>=2.0.7"]}

return Require("Novel35")("https://novel35.com", {
	id = 1788,
	name = "Novel35",
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/NovelFull.png",
	
	baseUrlInLinks = true,
	hasCloudFlare = true,
	meta_offset = 0,
	ajax_hot = "/search?type=hot",
	ajax_latest = "/search?type=latest",
	ajax_chapters = "/chapter-option",
	searchListSel = "list.list-truyen.col-xs-12",
	searchTitleSel = ".img-hover"
})
