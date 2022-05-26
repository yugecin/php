#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "mmparse.c"

struct php_mmp_data {
	char *d0, *d1, *d2, *d3;
	int len0, len1, len2, len3;
};

#define MMPEXTRAS_MAX_ANCHORS 200
#define MMPEXTRAS_MAX_NESTED_SECTIONS 10
#define MMPEXTRAS_MAX_NESTED_ULS 10
#include "mmparse_extras.c"

struct php_mmp_shared_userdata {
	struct {
		struct mmparse **mm;
		int num;
#define MAX_BLOGS 10
		char *htmlfile[MAX_BLOGS];
		char *txtfile[MAX_BLOGS];
	} blogs;
};

struct php_mmp_userdata {
	char *out_file_name;
	char did_config;
	char *title;
	char *modified;
	char *published;
	char is_blogpost;
	int blogpostidx;
	struct php_mmp_shared_userdata* shared;
	struct mmpextras_userdata mmpextras;
};

static
struct mmpextras_userdata *mmpextras_get_userdata(struct mmparse *mm)
{
	return &((struct php_mmp_userdata*) mm->config.userdata)->mmpextras;
}

static
void php_readfile(char *path, char **buf, int *length)
{
	register int size;
	FILE *in;

	in = fopen(path, "rb");
	if (!in) {
		fprintf(stderr, "failed to open file %s for reading", path);
		assert(0);
	}
	fseek(in, 0l, SEEK_END);
	size = *length = ftell(in);
	rewind(in);
	assert((*buf = (char*) malloc(size)));
	fread(*buf, size, 1, in);
	fclose(in);
}
/*jeanine:p:i:95;p:106;a:r;x:3.33;*/
static
void mmpextras_cb_placeholder_nop(struct mmparse *mm, struct mmp_output_part *output, void *data, int data_size)
{
}
/*jeanine:p:i:106;p:105;a:r;x:48.67;y:-23.56;*/
static
void *php_alloc_on_phdata_buffer(struct mmparse *mm, int size)
{
	return mmparse_allocate_placeholder(mm, mmpextras_cb_placeholder_nop, size)->data;/*jeanine:r:i:95;*/
}
/*jeanine:p:i:67;p:97;a:r;x:29.67;*/
static
void php_mmp_img_directive_validate_and_trunc_name(struct mmparse *mm, struct mmp_dir_content_data *data)
{
	struct mmp_dir_arg *src_arg;
	FILE *file;

	mmpextras_require_directive_argument(mm, data->directive, "alt"); /*just check if it's present*/
	src_arg = mmpextras_require_directive_argument(mm, data->directive, "src");
	assert(((void)"increase MMPARSE_DIRECTIVE_ARGV_MAX_LEN", src_arg->value_len < MMPARSE_DIRECTIVE_ARGV_MAX_LEN + 4));
	file = fopen(src_arg->value, "rb");
	if (file) {
		fclose(file);
	} else {
		mmparse_failmsgf(mm, "failed to open img file '%s' for reading", src_arg->value);
	}
	/*cut off the extra part of the tag name (ie make 'imgcaptioned' or 'imgcollapsed' into 'img')*/
	data->directive->name[3] = 0;
}
/*jeanine:p:i:97;p:72;a:r;x:10.00;y:-80.00;*/
static
enum mmp_dir_content_action php_mmp_dir_img(struct mmparse *mm, struct mmp_dir_content_data *data)
{
	struct mmp_dir_arg *alt_arg;
	register char *c;

	if (!data->content_len) {
		mmparse_failmsg(mm, "img needs alt text in the directive's contents");
		assert(0);
	}
	assert(((void) "increase MMPARSE_DIRECTIVE_MAX_ARGS", data->directive->argc < MMPARSE_DIRECTIVE_MAX_ARGS));
	assert(((void) "increase MMPARSE_DIRECTIVE_ARGV_MAX_LEN", data->content_len < MMPARSE_DIRECTIVE_ARGV_MAX_LEN));
	c = data->contents;
	while (*c) {
		if (*(c++) == '"') {
			/*since alt text is put in an attribute (using double quotes), disallow double quotes*/
			mmparse_failmsg(mm, "don't use double quotes in img alt text");
			assert(0);
		}
	}
	alt_arg = data->directive->args + data->directive->argc++;
	alt_arg->name_len = 3;
	alt_arg->value_len = data->content_len;
	memcpy(alt_arg->name, "alt", 4);
	memcpy(alt_arg->value, data->contents, data->content_len + 1);
	php_mmp_img_directive_validate_and_trunc_name(mm, data);/*jeanine:r:i:67;*/
	mmparse_append_to_expanded_line(mm, "<p class='img'>", 15);
	mmparse_print_tag_with_directives(mm, data->directive, "/>");
	mmparse_append_to_expanded_line(mm, "</p>", 4);
	return DELETE_CONTENTS;
}
/*jeanine:p:i:65;p:72;a:r;x:10.00;y:-47.00;*/
static
enum mmp_dir_content_action php_mmp_dir_imgcaptioned(struct mmparse *mm, struct mmp_dir_content_data *data)
{
	php_mmp_img_directive_validate_and_trunc_name(mm, data);/*jeanine:s:a:r;i:67;*/
	mmparse_append_to_expanded_line(mm, "<p class='img'>", 15);
	mmparse_print_tag_with_directives(mm, data->directive, "/><br/>");
	mmparse_append_to_closing_tag(mm, "</p>", 4);
	return LEAVE_CONTENTS;
}
/*jeanine:p:i:96;p:72;a:r;x:10.00;y:-40.00;*/
static
enum mmp_dir_content_action php_mmp_dir_blog(struct mmparse *mm, struct mmp_dir_content_data *data)
{
	struct php_mmp_userdata *ud, *ud2;
	char buf[200];
	int i, index, len;

	ud = mm->config.userdata;
	if (strncmp(data->contents, "blog", 4) || data->content_len < 5) {
		mmparse_failmsg(mm, "blog directive contents should be formatted like 'blog2'");
		assert(0);
	}
	index = atoi(data->contents + 4);
	for (i = 0; i < ud->shared->blogs.num; i++) {
		ud2 = ud->shared->blogs.mm[i]->config.userdata;
		if (ud2->is_blogpost && ud2->blogpostidx == index) {
			len = sprintf(buf, "<a href='%s'>blogpost: %s</a>", ud2->out_file_name, ud2->title);
			mmparse_append_to_expanded_line(mm, buf, len);
			return DELETE_CONTENTS;
		}
	}
	mmparse_failmsgf(mm, "cannot find blog with index %d", index);
	assert(0);
	return DELETE_CONTENTS;
}
/*jeanine:s:a:t;i:106;*/
/*jeanine:p:i:107;p:105;a:r;x:3.33;*/
static
void php_mmp_cb_placeholder_blogentry(struct mmparse *mm, struct mmp_output_part *output, void *data, int data_size)
{
	struct php_mmp_userdata *ud;
	int blogidx;

	blogidx = *(int*) data;
	ud = mm->config.userdata;
	ud = ud->shared->blogs.mm[blogidx]->config.userdata;
	assert(ud->published);
	assert(ud->title);
	mmparse_append_to_placeholder_output(mm, output, ud->published, strlen(ud->published));
	mmparse_append_to_placeholder_output(mm, output, " - ", 3);
	mmparse_append_to_placeholder_output(mm, output, ud->title, strlen(ud->title));
}
/*jeanine:p:i:105;p:72;a:r;x:10.00;y:-12.00;*/
static
enum mmp_dir_content_action php_mmp_dir_blogentry(struct mmparse *mm, struct mmp_dir_content_data *data)
{
	struct php_mmp_userdata *ud;
	char *html, *txt;
	int *phdata;

	ud = mm->config.userdata;
	assert(((void)"increase MAX_BLOGS", ud->shared->blogs.num < MAX_BLOGS));
	html = php_alloc_on_phdata_buffer(mm, data->content_len + 6);/*jeanine:r:i:106;*/
	txt = php_alloc_on_phdata_buffer(mm, data->content_len + 5);/*jeanine:s:a:r;i:106;*/
	sprintf(html, "%s.html", data->contents);
	sprintf(txt, "%s.txt", data->contents);
	ud->shared->blogs.htmlfile[ud->shared->blogs.num] = html;
	ud->shared->blogs.txtfile[ud->shared->blogs.num] = txt;
	ud->shared->blogs.num++;
	mmparse_append_to_expanded_line(mm, "<a href='", 9);
	mmparse_append_to_expanded_line(mm, html, data->content_len + 5);
	mmparse_append_to_expanded_line(mm, "'>", 2);
	phdata = mmparse_allocate_placeholder(mm, php_mmp_cb_placeholder_blogentry, sizeof(int))->data;/*jeanine:r:i:107;*/
	*phdata = ud->shared->blogs.num - 1;
	mmparse_append_to_expanded_line(mm, "</a>", 4);
	return DELETE_CONTENTS;
}
/*jeanine:p:i:104;p:72;a:r;x:10.00;y:14.00;*/
static
enum mmp_dir_content_action php_mmp_dir_br(struct mmparse *mm, struct mmp_dir_content_data *data)
{
	mmparse_append_to_expanded_line(mm, "<br/>", 5);
	return DELETE_CONTENTS;
}
/*jeanine:p:i:110;p:72;a:r;x:10.00;y:23.00;*/
static
enum mmp_dir_content_action php_mmp_dir_amp(struct mmparse *mm, struct mmp_dir_content_data *data)
{
	mmparse_append_to_expanded_line(mm, "&", 1);
	return DELETE_CONTENTS;
}
/*jeanine:p:i:109;p:72;a:r;x:10.00;y:31.00;*/
static
enum mmp_dir_content_action php_mmp_dir_lang(struct mmparse *mm, struct mmp_dir_content_data *data)
{
	char *col, *name;

	col = NULL;
	if (!strcmp("c", data->contents)) {
		name = "C";
		col = "555";
	} else if (!strcmp("cpp", data->contents)) {
		name = "C++";
		col = "f34b7d";
	} else if (!strcmp("c#", data->contents)) {
		name = "C#";
		col = "178600";
	} else if (!strcmp("java", data->contents)) {
		name = "Java";
		col = "b07219";
	} else if (!strcmp("shell", data->contents)) {
		name = "Shell";
		col = "89e051";
	} else if (!strcmp("php", data->contents)) {
		name = "PHP";
		col = "4f5d95";
	} else if (!strcmp("pawn", data->contents)) {
		name = "PAWN";
		col = "dbb284";
	} else if (!strcmp("asm", data->contents)) {
		name = "Assembly";
		col = "6e4c13";
	} else {
		name = data->contents;
	}
	mmparse_append_to_expanded_line(mm, "<span class='l' style='", 23);
	if (col) {
		mmparse_append_to_expanded_line(mm, "background:#", 12);
		mmparse_append_to_expanded_line(mm, col, strlen(col));
	} else {
		mmparse_append_to_expanded_line(mm, "border:1px solid #555", 21);
	}
	mmparse_append_to_expanded_line(mm, "'></span> ", 10);
	mmparse_append_to_expanded_line(mm, name, strlen(name));
	return DELETE_CONTENTS;
}
/*jeanine:p:i:72;p:75;a:r;x:9.22;y:-7.88;*/
struct mmp_dir_handler php_mmp_directives[] = {
	{ "img", php_mmp_dir_img },/*jeanine:r:i:97;*/
	{ "imgcaptioned", php_mmp_dir_imgcaptioned },/*jeanine:r:i:65;*/
	{ "anchor", mmpextras_dir_anchor },
	{ "index", mmpextras_dir_index },
	{ "href", mmpextras_dir_href },
	{ "a", mmpextras_dir_a },
	{ "h", mmpextras_dir_h },
	{ "blog", php_mmp_dir_blog },/*jeanine:r:i:96;*/
	{ "blogentry", php_mmp_dir_blogentry },/*jeanine:r:i:105;*/
	{ "br", php_mmp_dir_br },/*jeanine:r:i:104;*/
	{ "amp", php_mmp_dir_amp },/*jeanine:r:i:110;*/
	{ "lang", php_mmp_dir_lang },/*jeanine:r:i:109;*/
	{ NULL, NULL }
};
/*jeanine:p:i:100;p:102;a:r;x:16.67;y:-19.87;*/
static
int php_mmp_cb_mode_config_println(struct mmparse *mm)
{
	return 0;
}
/*jeanine:p:i:101;p:102;a:r;x:14.78;y:-3.12;*/
static
void php_mmp_cb_mode_config_end(struct mmparse *mm)
{
	register struct php_mmp_userdata *ud;

	ud = mm->config.userdata;
	if (!ud->title) {
		mmparse_failmsg(mm, "missing title");
		assert(0);
	}
	if (!ud->modified) {
		mmparse_failmsg(mm, "missing modified");
		assert(0);
	}
	if (ud->is_blogpost && !ud->published) {
		mmparse_failmsg(mm, "missing published");
		assert(0);
	}
	ud->did_config = 1;
}
/*jeanine:p:i:108;p:102;a:r;x:14.11;y:19.44;*/
static
enum mmp_dir_content_action php_mmp_cb_mode_config_directive(struct mmparse *mm, struct mmp_dir_content_data *data)
{
	struct php_mmp_userdata *ud;

	ud = mm->config.userdata;
	if (!strcmp(data->directive->name, "title")) {
		ud->title = php_alloc_on_phdata_buffer(mm, data->content_len + 1);
		strcpy(ud->title, data->contents);
		/*Register anchor with empty id so we can link to the page itself*/
		mmpextras_register_anchor(mm, /*id*/ "", 0, /*linktext*/ ud->title, data->content_len);
	} else if (!strcmp(data->directive->name, "modified")) {
		ud->modified = php_alloc_on_phdata_buffer(mm, data->content_len + 1);
		strcpy(ud->modified, data->contents);
	} else if (!strcmp(data->directive->name, "published")) {
		assert(ud->is_blogpost);
		ud->published = php_alloc_on_phdata_buffer(mm, data->content_len + 1);
		strcpy(ud->published, data->contents);
	} else {
		mmparse_failmsg(mm, "unknown config directive");
		assert(0);
	}
	return DELETE_CONTENTS;
}
/*jeanine:p:i:102;p:91;a:r;x:8.95;y:97.74;*/
struct mmp_mode php_mmp_mode_config = {
	mmparse_cb_mode_nop_start_end,
	php_mmp_cb_mode_config_println,/*jeanine:r:i:100;*/
	php_mmp_cb_mode_config_end,/*jeanine:r:i:101;*/
	php_mmp_cb_mode_config_directive,/*jeanine:r:i:108;*/
	"config",
	MMPARSE_DO_PARSE_LINES
};
/*jeanine:p:i:91;p:75;a:r;x:9.11;y:13.88;*/
struct mmp_mode *php_mmp_modes[] = {
	&mmpextras_mode_paragraphed, /*must be first*/
	&mmpextras_mode_section,
	&mmparse_mode_normal,
	&php_mmp_mode_config,/*jeanine:r:i:102;*/
	&mmparse_mode_plain,
	&mmpextras_mode_pre,
	&mmpextras_mode_ul,
	&mmparse_mode_nop,
	NULL
};
/*jeanine:p:i:76;p:88;a:r;x:21.26;*/
/**
Since all mmparse instance use the same big buffer, some offsets/sizefree need to be adjusted.

data0 is the main output, and must be offset
data1 is placeholder output, this can be overwritten because data in it should be used immediately
data2 is closingtag buffer, this can be overwritten because it's used immediately during parsing
data3 is placeholder data buffer, and must be offset
*/
static
void php_adjust_mmp_data_after_mmparse(struct php_mmp_data *mmpd, struct mmparse *mm)
{
	struct mmp_output_part *part;
	register int phbuf_used;

	for (part = mm->output; part->data0; part++) {
		mmpd->d0 += part->data0_len;
		mmpd->len0 -= part->data0_len;
	}
	phbuf_used = mm->ph.databuf - mmpd->d3;
	mmpd->d3 += phbuf_used;
	mmpd->len3 -= phbuf_used;
}
/*jeanine:p:i:75;p:88;a:r;x:21.30;y:-36.87;*/
static
struct mmparse *php_new_mmparse(struct php_mmp_shared_userdata *shared_ud, struct php_mmp_data *mmpd, char *src, char *target)
{
	static struct mmpextras_shared mmpextras_shared_ud;

	struct php_mmp_userdata *ud;
	struct mmparse *mm;

	if (!mmpextras_shared_ud.config.strpool) {
		assert(mmpextras_shared_ud.config.strpool = malloc(mmpextras_shared_ud.config.strpool_len = 8000));
	}
	assert(mm = malloc(sizeof(struct mmparse)));
	mm->config.directive_handlers = php_mmp_directives;/*jeanine:r:i:72;*/
	mm->config.modes = php_mmp_modes;/*jeanine:r:i:91;*/
	mm->config.dest.data0 = mmpd->d0;
	mm->config.dest.data1 = mmpd->d1;
	mm->config.dest.data2 = mmpd->d2;
	mm->config.dest.data3 = mmpd->d3;
	mm->config.dest.data0_len = mmpd->len0;
	mm->config.dest.data1_len = mmpd->len1;
	mm->config.dest.data2_len = mmpd->len2;
	mm->config.dest.data3_len = mmpd->len3;
	assert((mm->config.userdata = calloc(1, sizeof(struct php_mmp_userdata))));
	ud = mm->config.userdata;
	ud->out_file_name = target;
	ud->shared = shared_ud;
	ud->mmpextras.shared = &mmpextras_shared_ud;
	ud->mmpextras.config.target_file = target;
	ud->mmpextras.config.target_file_len = strlen(target);
	ud->mmpextras.config.section.no_continuation_breadcrumbs = 1;
	ud->mmpextras.config.section.no_breadcrumbs = 1;
	ud->mmpextras.config.section.no_end_index_links = 1;
	php_readfile(mm->config.debug_subject = src, &mm->config.source, &mm->config.source_len);
	return mm;
}
/*jeanine:p:i:103;p:98;a:r;x:3.33;*/
static
int php_mincss(char *css, int len)
{
	int has_bs, has_sc, was_comma, was_colon, has_space;
	char *src, *dest;
	register char c;

	has_bs = 0;
	has_sc = 0;
	was_comma = 0;
	has_space = 0;
	was_colon = 0;
	dest = src = css;
	while (len--) {
		c = *(src++);
		if (c == ' ') {
			if (was_comma) {
				was_comma = 0;
			} else if (was_colon) {
				was_colon = 0;
			} else {
				has_space = 1;
			}
			continue;
		} else {
			was_colon = 0;
			was_comma = 0;
		}
		if (has_space && !(c == '{' || c == '>' || c == '+')) {
			*(dest++) = ' ';
		}
		has_space = 0;
		switch (c) {
		case '\n':
			has_bs = 0;
			continue;
		case '\t':
			continue;
			break;
		case ',':
			was_comma = 1;
			break;
		case ':':
			was_colon = 1;
			break;
		case ';':
			has_sc = 1;
			continue;
		case ' ':
			has_space = 1;
			continue;
		case '}':
			has_sc = 0;
			break;
		case '\\':
			has_bs = 1;
			continue;
		}
		if (has_bs) {
			has_bs = 0;
			*(dest++) = '\\';
		}
		if (has_sc) {
			has_sc = 0;
			*(dest++) = ';';
		}
		*(dest++) = c;
	}
	return dest - css;
}
/*jeanine:p:i:98;p:88;a:r;x:13.79;y:8.27;*/
static
void php_output_page(struct mmparse *mm)
{
	static int skel0_len, skel1_len, skel2_len, skel3_len, css_len;
	static char *skel0, *skel1, *skel2, *skel3, *css;
	struct mmp_output_part *mmpart;
	FILE *file;

	struct php_mmp_userdata *ud;

	if (!skel0_len) {
		skel0 = "<!DOCTYPE html><html lang='en'><head><meta charset='utf-8'/><title>";
		skel1 = "</title><style>";
		skel2 =
			"</style></head><body><div><nav>"
			"<a href='index.html'>home/about</a> | "
			"<a href='projects.html'>projects</a> | "
			"<a href='blog.html'>blog</a>"
			"</nav><hr/>";
		skel3 = "</div></body></html>\n";
		skel0_len = strlen(skel0);
		skel1_len = strlen(skel1);
		skel2_len = strlen(skel2);
		skel3_len = strlen(skel3);
		php_readfile("style.css", &css, &css_len);
		css_len = php_mincss(css, css_len);/*jeanine:r:i:103;*/
	}

	ud = mm->config.userdata;
	if (!ud->did_config) {
		mmparse_failmsg(mm, "no config block");
		assert(0);
	}
	assert(file = fopen(ud->out_file_name, "wb"));
	fwrite(skel0, skel0_len, 1, file);
	fprintf(file, "%s", ud->title);
	fwrite(skel1, skel1_len, 1, file);
	fwrite(css, css_len, 1, file);
	fwrite(skel2, skel2_len, 1, file);
	if (ud->is_blogpost) {
		fprintf(file, "<p><a href='blog.html'>blog</a> &gt; %s (%s)</p>", ud->title, ud->published);
	}
	fprintf(file, "<h1>%s</h1>", ud->title);
	for (mmpart = mm->output; mmpart->data0; mmpart++) {
		fwrite(mmpart->data0, mmpart->data0_len, 1, file);
		fwrite(mmpart->data1, mmpart->data1_len, 1, file);
	}
	fprintf(file, "<footer><p><a href='%s'>txt</a> - ", mm->config.debug_subject);
	if (ud->is_blogpost) {
		fprintf(file, "published: %s - ", ud->published);
	}
	fprintf(file, "last modified: %s</p></footer>", ud->modified);
	fwrite(skel3, skel3_len, 1, file);
	fclose(file);
}
/*jeanine:p:i:88;p:0;a:b;y:15.88;*/
int main(int argc, char **argv)
{
	struct mmparse *mm_home, *mm_projects, *mm_blog, *mm;
	struct php_mmp_shared_userdata sud;
	struct php_mmp_userdata *ud;
	struct php_mmp_data mmpd;
	int i;

	memset(&sud, 0, sizeof(sud));
	assert(mmpd.d0 = malloc((mmpd.len0 = 150000) + (mmpd.len1 = 15000) + (mmpd.len2 = 5000) + (mmpd.len3 = 2000)));
	mmpd.d1 = mmpd.d0 + mmpd.len0;
	mmpd.d2 = mmpd.d1 + mmpd.len1;
	mmpd.d3 = mmpd.d2 + mmpd.len2;

	/*mmparse index*/
	mm_home = php_new_mmparse(&sud, &mmpd, "index.txt", "index.html");/*jeanine:r:i:75;*/
	mmparse(mm_home);
	php_adjust_mmp_data_after_mmparse(&mmpd, mm_home);/*jeanine:r:i:76;*/

	/*mmparse projects*/
	mm_projects = php_new_mmparse(&sud, &mmpd, "projects.txt", "projects.html");/*jeanine:s:a:r;i:75;*/
	mmparse(mm_projects);
	php_adjust_mmp_data_after_mmparse(&mmpd, mm_projects);/*jeanine:s:a:r;i:76;*/

	/*mmparse blog*/
	mm_blog = php_new_mmparse(&sud, &mmpd, "blog.txt", "blog.html");/*jeanine:s:a:r;i:75;*/
	mmparse(mm_blog);
	php_adjust_mmp_data_after_mmparse(&mmpd, mm_blog);/*jeanine:s:a:r;i:76;*/

	/*mmparse blogposts*/
	assert(sud.blogs.mm = malloc(sizeof(void*) * sud.blogs.num));
	for (i = 0; i < sud.blogs.num; i++) {
		mm = sud.blogs.mm[i] = php_new_mmparse(&sud, &mmpd, sud.blogs.txtfile[i], sud.blogs.htmlfile[i]);/*jeanine:s:a:r;i:75;*/
		ud = mm->config.userdata;
		ud->is_blogpost = 1;
		ud->mmpextras.config.section.no_continuation_breadcrumbs = 0;
		ud->mmpextras.config.section.no_breadcrumbs = 0;
		ud->mmpextras.config.section.no_end_index_links = 0;
		mmparse(mm);
		php_adjust_mmp_data_after_mmparse(&mmpd, mm);/*jeanine:s:a:r;i:76;*/
	}

	/*output*/
	mmparse_process_placeholders(mm_home);
	php_output_page(mm_home);/*jeanine:r:i:98;*/
	mmparse_process_placeholders(mm_projects);
	php_output_page(mm_projects);/*jeanine:s:a:r;i:98;*/
	mmparse_process_placeholders(mm_blog);
	php_output_page(mm_blog);
	for (i = 0; i < sud.blogs.num; i++) {
		mmparse_process_placeholders(sud.blogs.mm[i]);
		php_output_page(sud.blogs.mm[i]);/*jeanine:s:a:r;i:98;*/
	}

	return 0;
}
