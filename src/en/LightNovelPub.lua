-- {"id":1782,"ver":"0.0.9","libVer":"1.0.0","author":"Xanvial"}
local qs = Require("url").querystring

local defaults = {
	hot = "/stories-17091737/genre-all/order-popular/status-all",
	latest = "/stories-17091737/genre-all/order-updated/status-all",
	ranking = "/ranking-30091942",

	hasCloudFlare = false,
	hasSearch = true,
	chapterType = ChapterType.HTML
}

--- Get string from Element
--- @param v Element
--- @return string
local text = function(v)
	return v:text()
end

--- Concatenate two tables into one
--- @param t1 table
--- @param t2 table
--- @return table
local function tableConcat(t1,t2)
	for i=1,#t2 do
		t1[#t1+1] = t2[i]
	end
	return t1
end

function defaults:getPassage(url)
	local doc = GETDocument(self.expandURL(url))
	local title = doc:selectFirst(".chapter-title"):text()
	local htmlElement = doc:selectFirst(".chapter-content")

	---- Remove/modify unwanted HTML elements to get a clean webpage.
	htmlElement:removeAttr("style") -- Hopefully only temporary as a hotfix
	htmlElement:select("script"):remove()
	htmlElement:select("ins"):remove()
	htmlElement:select("div"):remove()

	-- Chapter title inserted before chapter text.
	htmlElement:child(0):before("<h1>" .. title .. "</h1>");

	return pageOfElem(htmlElement)
end

function defaults:parseNovel(url, loadChapters)
	local doc = GETDocument(self.expandURL(url))
	local info = NovelInfo()
	info:setTitle(doc:selectFirst("h1.novel-title"):text())

	local elem = doc:selectFirst("div.novel-info")

	info:setAuthors(map(elem:select("div.author a"), text))
	info:setGenres(map(elem:selectFirst("div.categories"):select("li a"), text))
	info:setStatus( ({
		Ongoing = NovelStatus.PUBLISHING,
		Completed = NovelStatus.COMPLETED
	})[elem:selectFirst(".header-stats"):select("span"):get(3):selectFirst("strong"):text()] )

	info:setImageURL(doc:selectFirst("div.fixed-img"):selectFirst("img"):attr("src"))

	local desc = ""
	local descParent = doc:selectFirst("div.summary div.content")
	-- check if element <p> exist
	local descP = descParent:select("p")
	if descP:size() > 0 then
		-- if exist, use it as description
		desc = table.concat(map(descP, text), "\n")
	else
		-- otherwise use the parent text
		desc = descParent:text()
	end
	info:setDescription(desc:gsub("<br>", "\n"))

	if loadChapters then
		local i = 0
		local stopLoop = true
		local curPage = 1
		local chapterTable = {}
		local pageUrl = ""

		-- loop each chapter list pages
		repeat
			if curPage > 1 then
				pageUrl = "/page-" .. curPage
			end
			local curDocs = GETDocument(self.expandURL(url) .. "/chapters" .. pageUrl)
			local nextButton = curDocs:selectFirst(".pagination"):select(".PagedList-skipToNext")
			if (nextButton ~= nil and nextButton:size() > 0) then
				curPage = curPage + 1
				stopLoop = false
			else
				stopLoop = true
			end
			local chList = curDocs:selectFirst("ul.chapter-list")
			chapterTable = tableConcat(chapterTable, map(
					chList:selectFirst(".chapter-list"):select("li a"),
					function(v)
						local chap = NovelChapter()
						chap:setLink(self.shrinkURL(v:attr("href")))
						chap:setTitle(v:attr("title"))
						chap:setOrder(i)
						i = i + 1
						return chap
					end))
		until (stopLoop)
		info:setChapters(AsList(chapterTable))
	end

	return info
end

---@param url string
function defaults:shrinkURL(url)
	return url:gsub(self.baseURL, "")
end

---@param url string
function defaults:expandURL(url)
	return self.baseURL .. url
end

function defaults:parseList(url)
	return map(GETDocument(url):selectFirst(".novel-list"):select(".cover-wrap"), function(v)
		local novel = Novel()
		novel:setImageURL(v:selectFirst("img"):attr("src"))
		local data = v:selectFirst("a")
		novel:setTitle(data:attr("title"))
		novel:setLink(self.shrinkURL(data:attr("href")))
		return novel
	end)
end

--- @return Novel[]
function defaults:search(data)
	local post = RequestDocument(POST(self.expandURL("/lnsearchlive"), nil,
			RequestBody(qs({ inputContent=data[QUERY] }), MediaType("application/x-www-form-urlencoded"))))
	return map(post:selectFirst(".novel-list"):select(".cover-wrap"), function(v)
		local novel = Novel()
		novel:setImageURL(v:selectFirst("img"):attr("src"))
		local data = v:selectFirst("a")
		novel:setTitle(data:attr("title"))
		novel:setLink(self.shrinkURL(data:attr("href")))
		return novel
	end)
end

--- @return Novel[]
function defaults:hotList(data)
	return self.parseList(self.baseURL .. self.hot .. "/p-"  .. data[PAGE])
end

--- @return Novel[]
function defaults:latestList(data)
	return self.parseList(self.baseURL .. self.latest .. "/p-"  .. data[PAGE])
end

--- @return Novel[]
function defaults:rankingList(data)
	return map(GETDocument(self.baseURL .. self.ranking):selectFirst(".rank-novels"):select(".novel-item"), function(v)
		local novel = Novel()
		novel:setImageURL(v:selectFirst("img"):attr("src"))
		local data = v:selectFirst("h2.title a")
		novel:setTitle(data:attr("title"))
		novel:setLink(self.shrinkURL(data:attr("href")))
		return novel
	end)
end

---@param baseURL string
local function novelData(baseURL, _self)
	_self = setmetatable(_self or {}, { __index = function(_, k)
		local d = defaults[k]
		return (type(d) == "function" and wrap(_self, d) or d)
	end })
	_self["baseURL"] = baseURL
	if not _self["base"] then
		_self["base"] = baseURL
	end
	_self["listings"] = {
		Listing("Hot", true, _self.hotList),
		Listing("Latest", true, _self.latestList),
		Listing("Ranking", false, _self.rankingList),
	}
	return _self
end

return novelData("https://webnovelpub.com", {
	id = 1782,
	name = "Light Novel Pub",
	imageURL = "https://static.webnovelpub.com/content/img/webnovelpub/logo.png",

	hasCloudFlare = true,
	hasSearch = false, -- todo
})
