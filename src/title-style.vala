namespace Flow {
    
    public enum TitleStyle {
        FLAT,
        SHADOW,
        SEPARATOR;
        
        public string[] get_css_styles() {
            switch (this) {
                case TitleStyle.FLAT:
                    return {};
                case TitleStyle.SHADOW:
                    return { "shadow" };
                case TitleStyle.SEPARATOR:
                    return { "separator" };
                default:
                    assert_not_reached();
            }
        }
    }
}