import Foundation

// MARK: - Task Template

/// Represents a reusable task template
/// The app comes with 300 pre-seeded templates
struct TaskTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let category: TaskTemplateCategory
    let suggestedLevel: TaskLevel
    let estimatedMinutes: Int
    let tags: [String]
    let isDefault: Bool  // true = pre-seeded by system
    let createdBy: UUID?  // parent who created custom template

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: TaskTemplateCategory,
        suggestedLevel: TaskLevel,
        estimatedMinutes: Int,
        tags: [String] = [],
        isDefault: Bool = false,
        createdBy: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.suggestedLevel = suggestedLevel
        self.estimatedMinutes = estimatedMinutes
        self.tags = tags
        self.isDefault = isDefault
        self.createdBy = createdBy
    }
}

// MARK: - Task Template Category

enum TaskTemplateCategory: String, Codable, CaseIterable, Identifiable {
    case kitchen = "Kitchen & Cooking"
    case indoorCleaning = "Indoor Cleaning"
    case outdoor = "Outdoor & Yard"
    case petCare = "Pet Care"
    case automotive = "Automotive"
    case errands = "Errands & Shopping"
    case siblingCare = "Sibling Care"
    case academic = "Academic & Study"
    case personalDevelopment = "Personal Development"
    case homeImprovement = "Home Improvement"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .kitchen: return "🍽️"
        case .indoorCleaning: return "🧹"
        case .outdoor: return "🌱"
        case .petCare: return "🐕"
        case .automotive: return "🚗"
        case .errands: return "🛒"
        case .siblingCare: return "👶"
        case .academic: return "📚"
        case .personalDevelopment: return "💪"
        case .homeImprovement: return "🔧"
        case .other: return "📋"
        }
    }
}

// MARK: - Default Task Templates

extension TaskTemplate {
    /// Get all 300 pre-seeded task templates
    static var defaultTemplates: [TaskTemplate] {
        return kitchenTasks + indoorCleaningTasks + outdoorTasks + petCareTasks +
               automotiveTasks + errandsTasks + siblingCareTasks + academicTasks +
               personalDevelopmentTasks + homeImprovementTasks
    }

    // MARK: - Kitchen & Cooking Tasks (40)

    private static var kitchenTasks: [TaskTemplate] {
        [
            // Daily Kitchen
            TaskTemplate(title: "Load dishwasher", description: "Load all dirty dishes, pots, and pans into dishwasher", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["daily", "dishes"], isDefault: true),
            TaskTemplate(title: "Unload dishwasher", description: "Put away all clean dishes in proper places", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["daily", "dishes"], isDefault: true),
            TaskTemplate(title: "Do the dishes", description: "Hand wash and dry all dishes, pots, and pans", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["daily", "washing"], isDefault: true),
            TaskTemplate(title: "Wipe down countertops", description: "Clean all kitchen countertops with cleaner", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["daily", "cleaning"], isDefault: true),
            TaskTemplate(title: "Wipe down dining table", description: "Clean dining table and chairs", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["daily", "cleaning"], isDefault: true),
            TaskTemplate(title: "Clean stovetop", description: "Scrub stovetop and remove all grease and food", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Clean microwave", description: "Clean inside and outside of microwave", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Sweep kitchen floor", description: "Sweep entire kitchen floor", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["daily", "floor"], isDefault: true),
            TaskTemplate(title: "Mop kitchen floor", description: "Mop entire kitchen floor thoroughly", category: .kitchen, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["floor"], isDefault: true),
            TaskTemplate(title: "Take out kitchen trash", description: "Empty trash and replace bag", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["daily"], isDefault: true),
            TaskTemplate(title: "Clean sink and faucet", description: "Scrub sink, faucet, and drain area", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["cleaning"], isDefault: true),

            // Cooking Tasks
            TaskTemplate(title: "Make breakfast for self", description: "Prepare and cook your own breakfast", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 20, tags: ["cooking"], isDefault: true),
            TaskTemplate(title: "Make breakfast for family", description: "Prepare breakfast for entire family", category: .kitchen, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["cooking", "family"], isDefault: true),
            TaskTemplate(title: "Pack school lunch", description: "Prepare and pack nutritious lunch", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["daily", "food"], isDefault: true),
            TaskTemplate(title: "Make simple dinner", description: "Cook a simple dinner (pasta, sandwiches, etc)", category: .kitchen, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["cooking", "dinner"], isDefault: true),
            TaskTemplate(title: "Make complex dinner", description: "Cook a full dinner with multiple dishes", category: .kitchen, suggestedLevel: .level4, estimatedMinutes: 75, tags: ["cooking", "dinner"], isDefault: true),
            TaskTemplate(title: "Prep ingredients for meal", description: "Chop vegetables, measure ingredients, prep cooking", category: .kitchen, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["cooking"], isDefault: true),
            TaskTemplate(title: "Bake cookies or dessert", description: "Make cookies, brownies, or dessert from scratch", category: .kitchen, suggestedLevel: .level3, estimatedMinutes: 60, tags: ["baking"], isDefault: true),
            TaskTemplate(title: "Set the table", description: "Set table with plates, utensils, napkins, drinks", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["daily", "dinner"], isDefault: true),
            TaskTemplate(title: "Clear the table", description: "Clear all dishes and wipe table after meal", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["daily"], isDefault: true),

            // Deep Kitchen Cleaning
            TaskTemplate(title: "Clean inside refrigerator", description: "Remove items, clean shelves, organize food", category: .kitchen, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["deep-cleaning"], isDefault: true),
            TaskTemplate(title: "Organize pantry", description: "Sort through pantry, organize by category, check dates", category: .kitchen, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["organizing"], isDefault: true),
            TaskTemplate(title: "Clean inside oven", description: "Deep clean oven interior", category: .kitchen, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["deep-cleaning"], isDefault: true),
            TaskTemplate(title: "Organize cabinets", description: "Organize kitchen cabinets and remove clutter", category: .kitchen, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["organizing"], isDefault: true),
            TaskTemplate(title: "Polish stainless appliances", description: "Clean and polish all stainless steel appliances", category: .kitchen, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["cleaning"], isDefault: true),
        ]
    }

    // MARK: - Indoor Cleaning Tasks (50)

    private static var indoorCleaningTasks: [TaskTemplate] {
        [
            // Bathroom
            TaskTemplate(title: "Clean toilet", description: "Scrub toilet bowl, seat, exterior thoroughly", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["bathroom"], isDefault: true),
            TaskTemplate(title: "Scrub shower/tub", description: "Deep clean shower or bathtub, remove soap scum", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["bathroom"], isDefault: true),
            TaskTemplate(title: "Clean bathroom sink", description: "Clean sink, counter, and faucet", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["bathroom"], isDefault: true),
            TaskTemplate(title: "Clean mirrors", description: "Clean all mirrors with glass cleaner", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["bathroom"], isDefault: true),
            TaskTemplate(title: "Mop bathroom floor", description: "Sweep and mop bathroom floor", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["bathroom", "floor"], isDefault: true),
            TaskTemplate(title: "Empty bathroom trash", description: "Empty trash and replace bag", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["bathroom"], isDefault: true),
            TaskTemplate(title: "Clean entire bathroom", description: "Complete bathroom cleaning: toilet, shower, sink, floor", category: .indoorCleaning, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["bathroom", "deep-cleaning"], isDefault: true),

            // Bedroom/Living
            TaskTemplate(title: "Make your bed", description: "Make bed with sheets, blankets, pillows arranged", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["daily", "bedroom"], isDefault: true),
            TaskTemplate(title: "Vacuum bedroom", description: "Vacuum entire bedroom floor", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["bedroom", "vacuuming"], isDefault: true),
            TaskTemplate(title: "Dust bedroom furniture", description: "Dust all surfaces in bedroom", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["bedroom", "dusting"], isDefault: true),
            TaskTemplate(title: "Clean your room", description: "Complete room cleaning: make bed, organize, vacuum, dust", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["bedroom"], isDefault: true),
            TaskTemplate(title: "Organize closet", description: "Sort clothes, hang items, organize shoes", category: .indoorCleaning, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["bedroom", "organizing"], isDefault: true),
            TaskTemplate(title: "Vacuum living room", description: "Vacuum all living room floors and under furniture", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["living-room", "vacuuming"], isDefault: true),
            TaskTemplate(title: "Vacuum stairs", description: "Vacuum all stairs thoroughly", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["vacuuming"], isDefault: true),
            TaskTemplate(title: "Dust living room", description: "Dust all surfaces, shelves, electronics in living room", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["living-room", "dusting"], isDefault: true),
            TaskTemplate(title: "Dust ceiling fans", description: "Clean all ceiling fan blades", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["dusting"], isDefault: true),
            TaskTemplate(title: "Clean windows", description: "Clean all windows inside and out", category: .indoorCleaning, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["windows"], isDefault: true),
            TaskTemplate(title: "Wipe baseboards", description: "Clean baseboards in entire room", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["deep-cleaning"], isDefault: true),
            TaskTemplate(title: "Organize bookshelf", description: "Organize and dust bookshelf", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["organizing"], isDefault: true),
            TaskTemplate(title: "Pick up common areas", description: "Tidy and organize living areas", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["organizing"], isDefault: true),

            // Laundry
            TaskTemplate(title: "Sort laundry", description: "Sort laundry by colors and fabric type", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["laundry"], isDefault: true),
            TaskTemplate(title: "Do a load of laundry", description: "Wash, dry, and fold one load of laundry", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["laundry"], isDefault: true),
            TaskTemplate(title: "Fold laundry", description: "Fold one full load of clean laundry", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["laundry"], isDefault: true),
            TaskTemplate(title: "Put away laundry", description: "Put all folded clothes in proper places", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["laundry"], isDefault: true),
            TaskTemplate(title: "Iron clothes", description: "Iron wrinkled clothes", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["laundry"], isDefault: true),

            // Deep Cleaning
            TaskTemplate(title: "Vacuum entire house", description: "Vacuum all rooms in the house", category: .indoorCleaning, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["vacuuming", "deep-cleaning"], isDefault: true),
            TaskTemplate(title: "Dust entire house", description: "Dust all surfaces in every room", category: .indoorCleaning, suggestedLevel: .level4, estimatedMinutes: 50, tags: ["dusting", "deep-cleaning"], isDefault: true),
            TaskTemplate(title: "Clean all doors", description: "Wipe down all interior doors", category: .indoorCleaning, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["deep-cleaning"], isDefault: true),
            TaskTemplate(title: "Clean air vents", description: "Vacuum and wipe all air vents", category: .indoorCleaning, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["deep-cleaning"], isDefault: true),
            TaskTemplate(title: "Organize coat closet", description: "Sort through and organize coat closet", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["organizing"], isDefault: true),
            TaskTemplate(title: "Clean garage", description: "Sweep, organize, and clean garage", category: .indoorCleaning, suggestedLevel: .level5, estimatedMinutes: 120, tags: ["garage", "deep-cleaning"], isDefault: true),
        ]
    }

    // MARK: - Outdoor & Yard Tasks (40)

    private static var outdoorTasks: [TaskTemplate] {
        [
            // Lawn Care
            TaskTemplate(title: "Mow front lawn", description: "Mow entire front yard", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 35, tags: ["lawn"], isDefault: true),
            TaskTemplate(title: "Mow back lawn", description: "Mow entire back yard", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 35, tags: ["lawn"], isDefault: true),
            TaskTemplate(title: "Mow entire lawn", description: "Mow both front and back yards", category: .outdoor, suggestedLevel: .level4, estimatedMinutes: 70, tags: ["lawn"], isDefault: true),
            TaskTemplate(title: "Edge lawn", description: "Edge along all walkways and driveway", category: .outdoor, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["lawn"], isDefault: true),
            TaskTemplate(title: "Trim hedges", description: "Trim and shape bushes and hedges", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["landscaping"], isDefault: true),
            TaskTemplate(title: "Rake leaves", description: "Rake and bag leaves in yard", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 50, tags: ["seasonal", "lawn"], isDefault: true),
            TaskTemplate(title: "Bag yard waste", description: "Collect and bag yard waste", category: .outdoor, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["lawn"], isDefault: true),
            TaskTemplate(title: "Pull weeds", description: "Pull weeds from garden beds and yard", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["gardening"], isDefault: true),
            TaskTemplate(title: "Water plants", description: "Water all outdoor plants and garden", category: .outdoor, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["gardening"], isDefault: true),
            TaskTemplate(title: "Plant flowers", description: "Plant new flowers or plants in garden", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["gardening"], isDefault: true),
            TaskTemplate(title: "Spread mulch", description: "Spread mulch in garden beds", category: .outdoor, suggestedLevel: .level4, estimatedMinutes: 75, tags: ["landscaping"], isDefault: true),

            // Outdoor Maintenance
            TaskTemplate(title: "Sweep driveway", description: "Sweep entire driveway", category: .outdoor, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Sweep walkways", description: "Sweep all walkways and paths", category: .outdoor, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Sweep patio/deck", description: "Sweep patio or deck area", category: .outdoor, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Clean gutters", description: "Remove leaves and debris from gutters", category: .outdoor, suggestedLevel: .level4, estimatedMinutes: 50, tags: ["maintenance"], isDefault: true),
            TaskTemplate(title: "Wash exterior windows", description: "Clean outside of all windows", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Pressure wash driveway", description: "Pressure wash entire driveway", category: .outdoor, suggestedLevel: .level4, estimatedMinutes: 75, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Pressure wash deck", description: "Pressure wash patio or deck", category: .outdoor, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Organize shed", description: "Organize storage shed or outdoor storage", category: .outdoor, suggestedLevel: .level4, estimatedMinutes: 75, tags: ["organizing"], isDefault: true),
            TaskTemplate(title: "Coil garden hose", description: "Properly coil and store garden hose", category: .outdoor, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["organizing"], isDefault: true),

            // Pool & Recreation
            TaskTemplate(title: "Skim pool surface", description: "Remove debris from pool surface", category: .outdoor, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["pool"], isDefault: true),
            TaskTemplate(title: "Vacuum pool", description: "Vacuum pool floor and walls", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["pool"], isDefault: true),
            TaskTemplate(title: "Clean pool filter", description: "Clean and maintain pool filter", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["pool"], isDefault: true),
            TaskTemplate(title: "Test pool water", description: "Test pool chemistry and adjust chemicals", category: .outdoor, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["pool"], isDefault: true),
            TaskTemplate(title: "Clean pool deck", description: "Sweep and clean pool deck area", category: .outdoor, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["pool"], isDefault: true),

            // Seasonal
            TaskTemplate(title: "Shovel snow - driveway", description: "Shovel snow from driveway", category: .outdoor, suggestedLevel: .level4, estimatedMinutes: 45, tags: ["seasonal", "winter"], isDefault: true),
            TaskTemplate(title: "Shovel snow - walkways", description: "Shovel snow from all walkways", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 25, tags: ["seasonal", "winter"], isDefault: true),
            TaskTemplate(title: "Salt icy areas", description: "Apply salt/sand to icy walkways and driveway", category: .outdoor, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["seasonal", "winter"], isDefault: true),
            TaskTemplate(title: "Clear snow off cars", description: "Remove snow from all family vehicles", category: .outdoor, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["seasonal", "winter"], isDefault: true),
        ]
    }

    // MARK: - Pet Care Tasks (25)

    private static var petCareTasks: [TaskTemplate] {
        [
            // Daily Pet Care
            TaskTemplate(title: "Feed dog/cat", description: "Feed pet breakfast or dinner", category: .petCare, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["daily"], isDefault: true),
            TaskTemplate(title: "Refill pet water", description: "Refill water bowls with fresh water", category: .petCare, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["daily"], isDefault: true),
            TaskTemplate(title: "Walk dog", description: "Take dog for walk around neighborhood", category: .petCare, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["daily", "dog"], isDefault: true),
            TaskTemplate(title: "Play with pet", description: "Play with pet for exercise and bonding", category: .petCare, suggestedLevel: .level1, estimatedMinutes: 20, tags: ["daily"], isDefault: true),
            TaskTemplate(title: "Scoop litter box", description: "Clean cat litter box", category: .petCare, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["daily", "cat"], isDefault: true),
            TaskTemplate(title: "Let dog outside/inside", description: "Let dog out to bathroom and bring back in", category: .petCare, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["daily", "dog"], isDefault: true),

            // Pet Grooming
            TaskTemplate(title: "Brush dog/cat", description: "Brush pet's fur thoroughly", category: .petCare, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["grooming"], isDefault: true),
            TaskTemplate(title: "Bathe dog", description: "Give dog a full bath", category: .petCare, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["grooming", "dog"], isDefault: true),
            TaskTemplate(title: "Clean pet bowls", description: "Wash all pet food and water bowls", category: .petCare, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Clean litter box completely", description: "Empty, scrub, and refill litter box", category: .petCare, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["cat", "cleaning"], isDefault: true),
            TaskTemplate(title: "Clean pet crate", description: "Clean and disinfect pet crate or cage", category: .petCare, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Clean up pet accident", description: "Clean up and disinfect pet mess", category: .petCare, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Vacuum pet hair", description: "Vacuum areas with pet hair buildup", category: .petCare, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["cleaning"], isDefault: true),

            // Pet Errands
            TaskTemplate(title: "Take pet to vet", description: "Transport pet to veterinary appointment", category: .petCare, suggestedLevel: .level3, estimatedMinutes: 60, tags: ["errands"], isDefault: true),
            TaskTemplate(title: "Buy pet supplies", description: "Shop for pet food and supplies", category: .petCare, suggestedLevel: .level2, estimatedMinutes: 40, tags: ["errands"], isDefault: true),
            TaskTemplate(title: "Clean fish tank", description: "Clean and maintain aquarium", category: .petCare, suggestedLevel: .level3, estimatedMinutes: 50, tags: ["fish"], isDefault: true),
        ]
    }

    // MARK: - Automotive Tasks (20)

    private static var automotiveTasks: [TaskTemplate] {
        [
            // Car Cleaning
            TaskTemplate(title: "Vacuum car interior", description: "Vacuum all seats, floors, and trunk", category: .automotive, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Wipe down dashboard", description: "Clean dashboard, console, and door panels", category: .automotive, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Clean car windows inside", description: "Clean inside of all car windows", category: .automotive, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Clean car windows outside", description: "Clean outside of all car windows", category: .automotive, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Wash car exterior", description: "Wash and rinse entire car exterior", category: .automotive, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Wax car", description: "Apply wax and polish car exterior", category: .automotive, suggestedLevel: .level4, estimatedMinutes: 80, tags: ["detailing"], isDefault: true),
            TaskTemplate(title: "Clean car seats", description: "Deep clean and shampoo car seats", category: .automotive, suggestedLevel: .level3, estimatedMinutes: 35, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Organize car trunk", description: "Clean out and organize trunk", category: .automotive, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["organizing"], isDefault: true),
            TaskTemplate(title: "Empty car trash", description: "Remove all trash from car", category: .automotive, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["cleaning"], isDefault: true),

            // Car Maintenance
            TaskTemplate(title: "Check tire pressure", description: "Check and adjust tire pressure on all tires", category: .automotive, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["maintenance"], isDefault: true),
            TaskTemplate(title: "Fill gas tank", description: "Fill car with gasoline", category: .automotive, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["maintenance"], isDefault: true),
            TaskTemplate(title: "Take car through car wash", description: "Drive car through automatic car wash", category: .automotive, suggestedLevel: .level1, estimatedMinutes: 20, tags: ["cleaning"], isDefault: true),
        ]
    }

    // MARK: - Errands & Shopping Tasks (20)

    private static var errandsTasks: [TaskTemplate] {
        [
            TaskTemplate(title: "Make grocery list", description: "Create shopping list for groceries", category: .errands, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["planning"], isDefault: true),
            TaskTemplate(title: "Go grocery shopping", description: "Complete grocery shopping trip", category: .errands, suggestedLevel: .level4, estimatedMinutes: 75, tags: ["shopping"], isDefault: true),
            TaskTemplate(title: "Put away groceries", description: "Unload and organize all groceries", category: .errands, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["organizing"], isDefault: true),
            TaskTemplate(title: "Pick up prescription", description: "Pick up medication from pharmacy", category: .errands, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["medical"], isDefault: true),
            TaskTemplate(title: "Return items to store", description: "Return purchased items to store", category: .errands, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["shopping"], isDefault: true),
            TaskTemplate(title: "Mail package", description: "Take package to post office", category: .errands, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["errands"], isDefault: true),
            TaskTemplate(title: "Drop off donations", description: "Take donation items to donation center", category: .errands, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["charity"], isDefault: true),
            TaskTemplate(title: "Pick up takeout food", description: "Pick up restaurant order", category: .errands, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["food"], isDefault: true),
        ]
    }

    // MARK: - Sibling Care Tasks (25)

    private static var siblingCareTasks: [TaskTemplate] {
        [
            TaskTemplate(title: "Watch younger sibling", description: "Supervise sibling for one hour", category: .siblingCare, suggestedLevel: .level3, estimatedMinutes: 60, tags: ["childcare"], isDefault: true),
            TaskTemplate(title: "Help sibling with homework", description: "Assist sibling with homework assignment", category: .siblingCare, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["academic"], isDefault: true),
            TaskTemplate(title: "Play with sibling", description: "Play games or activities with sibling", category: .siblingCare, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["play"], isDefault: true),
            TaskTemplate(title: "Read to sibling", description: "Read books to younger sibling", category: .siblingCare, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["educational"], isDefault: true),
            TaskTemplate(title: "Make snack for sibling", description: "Prepare snack for sibling", category: .siblingCare, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["food"], isDefault: true),
            TaskTemplate(title: "Make meal for sibling", description: "Prepare meal for sibling", category: .siblingCare, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["cooking"], isDefault: true),
            TaskTemplate(title: "Put sibling to bed", description: "Complete bedtime routine for sibling", category: .siblingCare, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["childcare"], isDefault: true),
            TaskTemplate(title: "Drive sibling to activity", description: "Transport sibling to event or activity", category: .siblingCare, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["transportation"], isDefault: true),
        ]
    }

    // MARK: - Academic Tasks (30)

    private static var academicTasks: [TaskTemplate] {
        [
            TaskTemplate(title: "Complete homework assignment", description: "Finish assigned homework", category: .academic, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["homework"], isDefault: true),
            TaskTemplate(title: "Study for test", description: "Study and review for upcoming test", category: .academic, suggestedLevel: .level3, estimatedMinutes: 60, tags: ["studying"], isDefault: true),
            TaskTemplate(title: "Work on school project", description: "Make progress on long-term project", category: .academic, suggestedLevel: .level4, estimatedMinutes: 75, tags: ["project"], isDefault: true),
            TaskTemplate(title: "Write essay or paper", description: "Write school essay or research paper", category: .academic, suggestedLevel: .level4, estimatedMinutes: 90, tags: ["writing"], isDefault: true),
            TaskTemplate(title: "Practice instrument", description: "Practice musical instrument", category: .academic, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["music"], isDefault: true),
            TaskTemplate(title: "Reading assignment", description: "Complete assigned reading", category: .academic, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["reading"], isDefault: true),
            TaskTemplate(title: "Math practice problems", description: "Complete math homework or practice", category: .academic, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["math"], isDefault: true),
            TaskTemplate(title: "Create presentation", description: "Prepare school presentation", category: .academic, suggestedLevel: .level4, estimatedMinutes: 70, tags: ["project"], isDefault: true),
            TaskTemplate(title: "Study vocabulary", description: "Learn and memorize vocabulary words", category: .academic, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["language"], isDefault: true),
            TaskTemplate(title: "Practice typing", description: "Practice typing skills", category: .academic, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["computer"], isDefault: true),
        ]
    }

    // MARK: - Personal Development Tasks (25)

    private static var personalDevelopmentTasks: [TaskTemplate] {
        [
            TaskTemplate(title: "Go for run", description: "Complete running workout", category: .personalDevelopment, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["exercise"], isDefault: true),
            TaskTemplate(title: "Bike ride", description: "Go for bike ride", category: .personalDevelopment, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["exercise"], isDefault: true),
            TaskTemplate(title: "Workout/exercise", description: "Complete exercise routine", category: .personalDevelopment, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["exercise"], isDefault: true),
            TaskTemplate(title: "Yoga session", description: "Complete yoga practice", category: .personalDevelopment, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["exercise", "wellness"], isDefault: true),
            TaskTemplate(title: "Sports practice", description: "Practice sport skills", category: .personalDevelopment, suggestedLevel: .level3, estimatedMinutes: 60, tags: ["sports"], isDefault: true),
            TaskTemplate(title: "Read for pleasure", description: "Read book for enjoyment", category: .personalDevelopment, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["reading"], isDefault: true),
            TaskTemplate(title: "Meditation", description: "Practice meditation or mindfulness", category: .personalDevelopment, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["wellness"], isDefault: true),
            TaskTemplate(title: "Journal writing", description: "Write in personal journal", category: .personalDevelopment, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["writing"], isDefault: true),
        ]
    }

    // MARK: - Home Improvement Tasks (20)

    private static var homeImprovementTasks: [TaskTemplate] {
        [
            TaskTemplate(title: "Replace light bulbs", description: "Replace burnt out light bulbs", category: .homeImprovement, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["maintenance"], isDefault: true),
            TaskTemplate(title: "Assemble furniture", description: "Assemble new furniture from box", category: .homeImprovement, suggestedLevel: .level4, estimatedMinutes: 90, tags: ["assembly"], isDefault: true),
            TaskTemplate(title: "Hang pictures", description: "Hang pictures or decorations on walls", category: .homeImprovement, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["decorating"], isDefault: true),
            TaskTemplate(title: "Organize tools", description: "Organize toolbox or tool storage", category: .homeImprovement, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["organizing"], isDefault: true),
            TaskTemplate(title: "Paint room", description: "Paint walls in room", category: .homeImprovement, suggestedLevel: .level5, estimatedMinutes: 180, tags: ["painting"], isDefault: true),
            TaskTemplate(title: "Install shelf", description: "Install wall shelf", category: .homeImprovement, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["installation"], isDefault: true),
        ]
    }
}
